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
    typealias CachedCustomerInfoProvider = @MainActor () -> CustomerInfo?
    typealias PreferredUILocaleProvider = @MainActor () -> String?

    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    private let cachedCustomerInfoProvider: CachedCustomerInfoProvider
    private let preferredUILocaleProvider: PreferredUILocaleProvider
    private let checkpointPresenter: CheckpointPresenterType
    private let errorPresentationQueue = ErrorPresentationQueue()
    var paywallPresenter: PaywallPresenter?
    var errorPresenter: ErrorPresenter?

    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        checkpointPresenter: CheckpointPresenterType? = nil,
        cachedCustomerInfoProvider: @escaping CachedCustomerInfoProvider = { nil },
        preferredUILocaleProvider: @escaping PreferredUILocaleProvider = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
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

    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointPresentationOutcome {
        let globalPaywallPresenter = self.paywallPresenter

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .nothingPresented
        }

        let resolution = try await self.resolveCheckpoint(identifier, params)
        return try await self.executeCheckpoint(
            identifier: identifier,
            params: params,
            resolution: resolution,
            globalPaywallPresenter: globalPaywallPresenter
        )
    }

    private func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams,
        resolution: CheckpointResolution,
        globalPaywallPresenter: PaywallPresenter?
    ) async throws -> CheckpointPresentationOutcome {
        let errorPresentationHandler = self.errorPresentationHandler(for: params)

        switch resolution {
        case let .matchedWorkflow(workflow):
            let presentation = WorkflowPresentationRequest(
                checkpointIdentifier: identifier,
                workflow: workflow,
                customVariables: params.customVariables,
                presentationMode: params.presentationMode,
                initialActiveEntitlementIdentifiers: self.initialActiveEntitlementIdentifiers(),
                errorPresentationHandler: errorPresentationHandler
            )
            return try await self.checkpointPresenter.presentWorkflow(presentation)
        case let .matchedOffering(offering):
            return try await self.checkpointPresenter.presentOffering(
                params: .init(
                    checkpointIdentifier: identifier,
                    customVariables: params.customVariables,
                    presentationMode: params.presentationMode,
                    offering: offering,
                    errorPresentationHandler: errorPresentationHandler
                ),
                globalPaywallPresenter: globalPaywallPresenter,
                localPaywallPresentationHandler: params.localPaywallPresentationHandler
            )
        case .noAction:
            return .nothingPresented
        }
    }

    func checkpointForCallback(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointCallbackResult {
        switch await self.checkpointOutcome(identifier: identifier, params: params) {
        case let .completed(result):
            return .completed(CheckpointResult(flow: result))
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
        case let .synchronizationFailed(error):
            await self.presentCheckpointError(
                error,
                identifier: identifier,
                params: params,
                kind: .flowResultSyncFailed
            )
            return .completed(CheckpointResult(
                flow: FlowResult(obtainedEntitlements: [])
            ))
        }
    }

    private func checkpointOutcome(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointOutcome {
        let initialActiveEntitlementIdentifiers = self.initialActiveEntitlementIdentifiers()
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

        switch resolution {
        case .noAction(.configurationUnavailable):
            return .failed(CheckpointError.configurationUnavailable)
        case .noAction(.unknownCheckpoint), .noAction(.noMatch):
            return .completed(nil)
        case .matchedWorkflow, .matchedOffering:
            break
        }

        do {
            switch try await self.executeCheckpoint(
                identifier: identifier,
                params: params,
                resolution: resolution,
                globalPaywallPresenter: globalPaywallPresenter
            ) {
            case let .completed(customerInfo):
                return .completed(self.flowResult(
                    customerInfo: customerInfo,
                    initialActiveEntitlementIdentifiers: initialActiveEntitlementIdentifiers
                ))
            case let .synchronizationFailed(error):
                return .synchronizationFailed(error)
            case .backedOut, .failed, .nothingPresented:
                return .suppressed
            }
        } catch CheckpointError.operationAlreadyInProgress,
                CheckpointError.presentationContextBusy {
            return .suppressed
        } catch {
            return .failed(error)
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

    private func flowResult(
        customerInfo: CustomerInfo?,
        initialActiveEntitlementIdentifiers: Set<String>?
    ) -> FlowResult {
        let obtainedEntitlements = customerInfo?
            .obtainedEntitlements(comparedTo: initialActiveEntitlementIdentifiers)
            .map(ObtainedEntitlement.init)
            ?? []

        return FlowResult(obtainedEntitlements: Set(obtainedEntitlements))
    }

    private func initialActiveEntitlementIdentifiers() -> Set<String>? {
        return self.cachedCustomerInfoProvider().map { customerInfo in
            Set(customerInfo.entitlements.active.keys)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointCallbackResult {
    case completed(CheckpointResult)
    case suppressed
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum CheckpointOutcome {
    case completed(FlowResult?)
    case suppressed
    case failed(any Error)
    case synchronizationFailed(any Error)
}
