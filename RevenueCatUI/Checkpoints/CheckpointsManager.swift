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

    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    private let cachedCustomerInfoProvider: CachedCustomerInfoProvider
    private let checkpointPresenter: CheckpointPresenterType
    var paywallPresenter: PaywallPresenter?
    var adPresenter: AdPresenter?

    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        checkpointPresenter: CheckpointPresenterType? = nil,
        cachedCustomerInfoProvider: @escaping CachedCustomerInfoProvider = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.checkpointPresenter = checkpointPresenter ?? CheckpointPresenter(
            workflowPresenter: WorkflowPresenter(),
            cachedCustomerInfoProvider: cachedCustomerInfoProvider,
            customerInfoSynchronizer: customerInfoSynchronizer
        )
    }

    func setPaywallPresenter(_ presenter: PaywallPresenter?) {
        self.paywallPresenter = presenter
    }

    func setAdPresenter(_ presenter: AdPresenter?) {
        self.adPresenter = presenter
    }

    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointPresentationOutcome {
        let globalPaywallPresenter = self.paywallPresenter
        let adPresenter = self.adPresenter

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .nothingPresented
        }

        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let presentation = WorkflowPresentationRequest(
                workflow: workflow,
                customVariables: params.customVariables,
                initialActiveEntitlementIdentifiers: self.initialActiveEntitlementIdentifiers()
            )
            return try await self.checkpointPresenter.presentWorkflow(presentation)
        case let .matchedOffering(offering):
            return try await self.checkpointPresenter.presentOffering(
                params: .init(
                    checkpointIdentifier: identifier,
                    customVariables: params.customVariables,
                    offering: offering
                ),
                globalPaywallPresenter: globalPaywallPresenter,
                localPaywallPresentationHandler: params.localPaywallPresentationHandler
            )
        case let .matchedAd(adStep):
            guard let adPresenter else {
                Logger.warning(Strings.checkpoint_ad_step_without_ad_presenter(checkpointIdentifier: identifier))
                return .nothingPresented
            }
            return try await self.checkpointPresenter.presentAd(
                params: .init(
                    checkpointIdentifier: identifier,
                    customVariables: params.customVariables,
                    adIdentifier: adStep.adIdentifier,
                    mediator: adStep.mediator
                ),
                adPresenter: adPresenter
            )
        case .noAction:
            return .nothingPresented
        }
    }

    func checkpointForCallback(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointCallbackResult {
        let initialActiveEntitlementIdentifiers = self.initialActiveEntitlementIdentifiers()

        do {
            switch try await self.executeCheckpoint(identifier: identifier, params: params) {
            case .backedOut:
                return .suppressed
            case let .completed(customerInfo):
                return .completed(self.flowResult(
                    customerInfo: customerInfo,
                    initialActiveEntitlementIdentifiers: initialActiveEntitlementIdentifiers
                ))
            case let .adPresented(adOutcome):
                return .completed(adOutcome is CheckpointAdOutcome.Failed ? nil : FlowResult())
            case .failed, .nothingPresented:
                return .completed(nil)
            }
        } catch CheckpointError.operationAlreadyInProgress {
            return .suppressed
        } catch {
            return .completed(nil)
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
    case completed(FlowResult?)
    case suppressed
}
