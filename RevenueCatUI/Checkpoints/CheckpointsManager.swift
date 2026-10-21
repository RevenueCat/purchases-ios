//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsManager.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Orchestrates checkpoint resolution and workflow execution.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointsManager {

    typealias CustomerInfoSynchronizer = @MainActor () async throws -> CustomerInfo
    typealias CustomerInfoProvider = @MainActor () async throws -> CustomerInfo
    typealias CachedCustomerInfoProvider = @MainActor () -> CustomerInfo?
    typealias PreferredUILocaleProvider = @MainActor () -> String?

    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    private let customerInfoProvider: CustomerInfoProvider
    private let cachedCustomerInfoProvider: CachedCustomerInfoProvider
    private let preferredUILocaleProvider: PreferredUILocaleProvider
    private let checkpointPresenter: CheckpointPresenterType
    private let errorPresentationQueue = ErrorPresentationQueue()
    var paywallPresenter: PaywallPresenter?
    var errorPresenter: ErrorPresenter?

    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        customerInfoProvider: @escaping CustomerInfoProvider,
        checkpointPresenter: CheckpointPresenterType? = nil,
        cachedCustomerInfoProvider: @escaping CachedCustomerInfoProvider = { nil },
        preferredUILocaleProvider: @escaping PreferredUILocaleProvider = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.customerInfoProvider = customerInfoProvider
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.preferredUILocaleProvider = preferredUILocaleProvider
        self.checkpointPresenter = checkpointPresenter ?? CheckpointPresenter(
            workflowPresenter: WorkflowPresenter(),
            cachedCustomerInfoProvider: cachedCustomerInfoProvider,
            customerInfoSynchronizer: customerInfoSynchronizer
        )
    }

    func setPaywallPresenter(_ presenter: PaywallPresenter?) {
        self.paywallPresenter = presenter
    }

    func setErrorPresenter(_ presenter: ErrorPresenter?) {
        self.errorPresenter = presenter
    }

    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointPresentationOutcome {
        return try await self.executeCheckpointWithContext(identifier: identifier, params: params).outcome
    }

    private func executeCheckpointWithContext(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointExecutionResult {
        let globalPaywallPresenter = self.paywallPresenter

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .init(outcome: .nothingPresented)
        }

        let resolution = try await self.resolveCheckpoint(identifier, params)
        let customerInfoBefore = try await self.customerInfoBefore(identifier: identifier)
        return try await self.executeCheckpoint(
            identifier: identifier,
            params: params,
            resolution: resolution,
            customerInfoBefore: customerInfoBefore,
            globalPaywallPresenter: globalPaywallPresenter
        )
    }

    private func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams,
        resolution: CheckpointResolution,
        customerInfoBefore: CustomerInfo,
        globalPaywallPresenter: PaywallPresenter?
    ) async throws -> CheckpointExecutionResult {
        let errorPresentationHandler = self.errorPresentationHandler(for: params)

        switch resolution {
        case let .matchedWorkflow(workflow):
            let presentation = WorkflowPresentationRequest(
                checkpointIdentifier: identifier,
                workflow: workflow,
                customVariables: params.customVariables,
                presentationMode: params.presentationMode,
                initialActiveEntitlementIdentifiers: customerInfoBefore.activeEntitlementIdentifiers,
                errorPresentationHandler: errorPresentationHandler
            )
            return .init(
                outcome: try await self.checkpointPresenter.presentWorkflow(presentation),
                availableProducts: workflow.offerings.all.values.flatMap(\.availablePackages).map(\.storeProduct)
            )
        case let .matchedOffering(offering, _):
            return .init(
                outcome: try await self.checkpointPresenter.presentOffering(
                    params: .init(
                        checkpointIdentifier: identifier,
                        customVariables: params.customVariables,
                        presentationMode: params.presentationMode,
                        offering: offering,
                        errorPresentationHandler: errorPresentationHandler
                    ),
                    globalPaywallPresenter: globalPaywallPresenter,
                    localPaywallPresentationHandler: params.localPaywallPresentationHandler
                ),
                availableProducts: offering.availablePackages.map(\.storeProduct)
            )
        case .noAction:
            return .init(outcome: .nothingPresented)
        }
    }

    func checkpointForCallback(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointCallbackResult {
        switch await self.checkpointOutcome(identifier: identifier, params: params) {
        case let .completed(result):
            return .completed(result)
        case .suppressed:
            return .suppressed
        case let .failed(error):
            await self.presentCheckpointError(
                error,
                identifier: identifier,
                params: params,
                kind: .flowCouldNotBeShown
            )
            return .suppressed
        case let .synchronizationFailed(error, fallback):
            await self.presentCheckpointError(
                error,
                identifier: identifier,
                params: params,
                kind: .flowResultSyncFailed
            )
            return .completed(fallback)
        }
    }

    private func checkpointOutcome(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointOutcome {
        let globalPaywallPresenter = self.paywallPresenter

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .failed(CheckpointError.invalidIdentifier(identifier))
        }

        let resolution: CheckpointResolution
        do {
            resolution = try await self.resolveCheckpoint(identifier, params)
        } catch {
            return .failed(error)
        }

        let customerInfoBefore: CustomerInfo
        do {
            customerInfoBefore = try await self.customerInfoBefore(identifier: identifier)
        } catch {
            return .failed(error)
        }

        switch resolution {
        case .noAction(.configurationUnavailable):
            return .failed(CheckpointError.configurationUnavailable)
        case .noAction(.unknownCheckpoint), .noAction(.noMatch):
            return .completed(CheckpointResult(flow: nil, customer: customerInfoBefore))
        case .matchedWorkflow, .matchedOffering:
            return await self.presentedOutcome(
                identifier: identifier,
                params: params,
                resolution: resolution,
                customerInfoBefore: customerInfoBefore,
                globalPaywallPresenter: globalPaywallPresenter
            )
        }
    }

    private func presentedOutcome(
        identifier: String,
        params: CheckpointCallParams,
        resolution: CheckpointResolution,
        customerInfoBefore: CustomerInfo,
        globalPaywallPresenter: PaywallPresenter?
    ) async -> CheckpointOutcome {
        do {
            let execution = try await self.executeCheckpoint(
                identifier: identifier,
                params: params,
                resolution: resolution,
                customerInfoBefore: customerInfoBefore,
                globalPaywallPresenter: globalPaywallPresenter
            )
            switch execution.outcome {
            case let .completed(customerInfo):
                return .completed(self.checkpointResult(
                    customerInfo: customerInfo,
                    customerInfoBefore: customerInfoBefore,
                    availableProducts: execution.availableProducts
                ))
            case let .synchronizationFailed(error):
                return .synchronizationFailed(error, fallback: self.checkpointResult(
                    customerInfo: nil,
                    customerInfoBefore: customerInfoBefore,
                    availableProducts: execution.availableProducts
                ))
            case .backedOut, .failed, .nothingPresented:
                return .suppressed
            }
        } catch CheckpointError.operationAlreadyInProgress,
                CheckpointError.presentationContextUnavailable {
            return .suppressed
        } catch {
            return .failed(error)
        }
    }

    /// The customer's information read once the checkpoint is resolved and before anything is presented: cached
    /// when warm, fetched otherwise, so a run that goes on always has one to deliver and to compare against. It comes
    /// after resolving so the checkpoint hit is tracked either way, and so the resolver's own read has already
    /// warmed the cache for a configured checkpoint.
    private func customerInfoBefore(identifier: String) async throws -> CustomerInfo {
        do {
            return try await self.customerInfoProvider()
        } catch {
            Logger.error(
                "Checkpoint '\(identifier)': the customer's information could not be read: " +
                error.localizedDescription
            )
            throw error
        }
    }

    /// The result of a passed flow. Its customer is the information the flow itself produced (a purchase, a restore
    /// that granted access, or the sync after an app-owned paywall), else the latest cached copy (a restore that
    /// granted nothing new, or a web checkout, refreshed it without being an outcome), else `customerInfoBefore`,
    /// which the cache can only have lost to an identity change meanwhile. Whatever the outcome, what was obtained
    /// is read from that customer against `customerInfoBefore`.
    private func checkpointResult(
        customerInfo: CustomerInfo?,
        customerInfoBefore: CustomerInfo,
        availableProducts: [StoreProduct]
    ) -> CheckpointResult {
        let customer = customerInfo ?? self.cachedCustomerInfoProvider() ?? customerInfoBefore
        let obtainedEntitlements = customer
            .obtainedEntitlements(comparedTo: customerInfoBefore.activeEntitlementIdentifiers)
            .map(ObtainedEntitlement.init)
        let obtainedProducts = customer.obtainedProducts(comparedTo: customerInfoBefore, from: availableProducts)

        return CheckpointResult(
            flow: FlowResult(
                obtainedEntitlements: Set(obtainedEntitlements),
                obtainedProducts: Set(obtainedProducts)
            ),
            customer: customer
        )
    }

}

// MARK: - Error presentation handlers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointsManager {

    func errorPresentationHandler(
        for params: CheckpointCallParams,
        defaultHandler makeDefaultHandler: @escaping () -> ErrorPresentationHandler
    ) -> ErrorPresentationHandler {
        if let localHandler = params.localErrorPresentationHandler {
            return { [errorPresentationQueue] params, completion in
                errorPresentationQueue.enqueue(
                    params: params,
                    handler: localHandler,
                    completion: completion
                )
            }
        }

        var defaultHandler: ErrorPresentationHandler?
        return { [weak self, errorPresentationQueue] params, completion in
            let handler: ErrorPresentationHandler
            if let globalPresenter = self?.errorPresenter {
                handler = { params, completion in
                    globalPresenter.present(params: params, completion: completion)
                }
            } else {
                let resolvedDefaultHandler = defaultHandler ?? makeDefaultHandler()
                defaultHandler = resolvedDefaultHandler
                handler = resolvedDefaultHandler
            }

            errorPresentationQueue.enqueue(
                params: params,
                handler: handler,
                completion: completion
            )
        }
    }

    private func presentCheckpointError(
        _ error: any Error,
        identifier: String,
        params: CheckpointCallParams,
        kind: CheckpointFailureKind
    ) async {
        let errorPresentationHandler = self.errorPresentationHandler(for: params)

        await withCheckedContinuation { continuation in
            errorPresentationHandler(
                .init(
                    checkpointIdentifier: identifier,
                    error: error,
                    customVariables: params.customVariables,
                    kind: kind
                ),
                .init { continuation.resume() }
            )
        }
    }

    private func errorPresentationHandler(for params: CheckpointCallParams) -> ErrorPresentationHandler {
        return self.errorPresentationHandler(
            for: params,
            defaultHandler: {
                let preferredUILocaleProvider = self.preferredUILocaleProvider
                let presenter = DefaultErrorPresenter(preferredUILocaleProvider: preferredUILocaleProvider)
                return { params, completion in
                    presenter.present(params: params, completion: completion)
                }
            }
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CheckpointExecutionResult {

    let outcome: CheckpointPresentationOutcome
    let availableProducts: [StoreProduct]

    init(outcome: CheckpointPresentationOutcome, availableProducts: [StoreProduct] = []) {
        self.outcome = outcome
        self.availableProducts = availableProducts
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointCallbackResult {
    case completed(CheckpointResult)
    case suppressed
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum CheckpointOutcome {
    case completed(CheckpointResult)
    case suppressed
    case failed(any Error)
    /// The flow passed but its sync failed: `fallback` is delivered once the error has been presented.
    case synchronizationFailed(any Error, fallback: CheckpointResult)
}
