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
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointsManager {

    typealias CustomerInfoSynchronizer = @MainActor () async throws -> CustomerInfo

    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    private let cachedCustomerInfoProvider: @MainActor () -> CustomerInfo?
    private let customerInfoSynchronizer: CustomerInfoSynchronizer
    @MainActor private lazy var workflowPresenter: CheckpointWorkflowPresenterProtocol = CheckpointWorkflowPresenter()
    @MainActor private lazy var checkpointPresenter = CheckpointPresenter(
        workflowPresenter: self.workflowPresenter,
        customerInfoSynchronizer: self.customerInfoSynchronizer
    )

    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        cachedCustomerInfoProvider: @escaping @MainActor () -> CustomerInfo? = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.customerInfoSynchronizer = customerInfoSynchronizer
    }

    @MainActor
    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        workflowPresenter: CheckpointWorkflowPresenterProtocol,
        cachedCustomerInfoProvider: @escaping @MainActor () -> CustomerInfo? = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.customerInfoSynchronizer = customerInfoSynchronizer
        self.workflowPresenter = workflowPresenter
    }

    @MainActor
    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        workflowPresenter: CheckpointWorkflowPresenterProtocol,
        defaultPaywallPresenter: DefaultPaywallPresenterProtocol,
        cachedCustomerInfoProvider: @escaping @MainActor () -> CustomerInfo? = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfoProvider = cachedCustomerInfoProvider
        self.customerInfoSynchronizer = customerInfoSynchronizer
        self.workflowPresenter = workflowPresenter
        self.checkpointPresenter = CheckpointPresenter(
            workflowPresenter: workflowPresenter,
            defaultPaywallPresenter: defaultPaywallPresenter,
            customerInfoSynchronizer: customerInfoSynchronizer
        )
    }

    @MainActor
    func setPaywallPresenter(_ presenter: PaywallPresenter?) {
        self.checkpointPresenter.paywallPresenter = presenter
    }

    @MainActor
    var paywallPresenter: PaywallPresenter? {
        get { return self.checkpointPresenter.paywallPresenter }
        set { self.setPaywallPresenter(newValue) }
    }

    @MainActor
    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointExecution {
        let globalPaywallPresenter = self.paywallPresenter

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .nothingPresented
        }

        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let presentation = CheckpointPresentation(
                workflow: workflow,
                customVariables: params.customVariables
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
        case .noAction:
            return .nothingPresented
        }
    }

    @MainActor
    func checkpointForCallback(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointCallbackResult {
        let initialEntitlementIdentifiers = self.cachedCustomerInfoProvider().map { customerInfo in
            Set(customerInfo.entitlements.active.keys)
        }

        do {
            switch try await self.executeCheckpoint(identifier: identifier, params: params) {
            case .backedOut:
                return .suppressed
            case let .completed(outcome):
                return .completed(self.flowResult(
                    for: outcome,
                    initialEntitlementIdentifiers: initialEntitlementIdentifiers
                ))
            case .nothingPresented:
                return .completed(nil)
            }
        } catch CheckpointError.operationAlreadyInProgress {
            return .suppressed
        } catch {
            return .completed(nil)
        }
    }

    @MainActor
    private func flowResult(
        for outcome: CheckpointFlowOutcome,
        initialEntitlementIdentifiers: Set<String>?
    ) -> FlowResult? {
        let entitlements: [EntitlementInfo]
        switch outcome {
        case let .purchased(_, customerInfo),
             let .restored(customerInfo),
             let .finished(customerInfo):
            entitlements = Array(customerInfo.entitlements.active.values)
        case .error:
            return nil
        case .dismissed, .webCheckoutOpened:
            entitlements = []
        }

        let obtainedEntitlements = entitlements.lazy
            .filter { entitlement in
                guard let initialEntitlementIdentifiers else { return true }
                return !initialEntitlementIdentifiers.contains(entitlement.identifier)
            }
            .map(ObtainedEntitlement.init)

        return FlowResult(obtainedEntitlements: Set(obtainedEntitlements))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointCallbackResult {
    case completed(FlowResult?)
    case suppressed
}
