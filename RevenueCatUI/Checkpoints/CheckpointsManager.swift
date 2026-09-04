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

/// Orchestrates checkpoint resolution, workflow execution, and listener delivery.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointsManager {

    var listener: CheckpointListener? {
        get {
            self.listenerLock.lock()
            defer { self.listenerLock.unlock() }
            return self.storedListener
        }
        set {
            self.listenerLock.lock()
            self.storedListener = newValue
            self.listenerLock.unlock()
        }
    }

    private let listenerLock = NSLock()
    private var storedListener: CheckpointListener?
    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    private let cachedCustomerInfo: @MainActor () -> CustomerInfo?
    @MainActor private lazy var executor: CheckpointExecutor = CheckpointWorkflowExecutor()

    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        cachedCustomerInfo: @escaping @MainActor () -> CustomerInfo? = { nil }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfo = cachedCustomerInfo
    }

    @MainActor
    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        executor: CheckpointExecutor,
        cachedCustomerInfo: @escaping @MainActor () -> CustomerInfo? = { nil }
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.cachedCustomerInfo = cachedCustomerInfo
        self.executor = executor
    }

    func checkpointGate(
        identifier: String,
        params: CheckpointCallParams,
        completion: @escaping (CheckpointGateResult) -> Void
    ) {
        Task { @MainActor in
            completion(await self.checkpointGate(identifier: identifier, params: params))
        }
    }

    @MainActor
    func checkpointGate(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointGateResult {
        let initialEntitlements = Set((self.cachedCustomerInfo()?.entitlements.active ?? [:]).keys)
        do {
            let result = try await self.checkpoint(identifier: identifier, params: params)
            return self.gateResult(for: result, initialEntitlements: initialEntitlements)
        } catch is CancellationError {
            return CheckpointGateResult(noActionReason: .error, error: CancellationError() as NSError)
        } catch {
            return CheckpointGateResult(noActionReason: .error, error: error as NSError)
        }
    }

    @MainActor
    func checkpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointResult {
        self.listener?.onCheckpointHit(CheckpointContext.Hit(identifier: identifier, params: params))

        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            let result = CheckpointResult.NoAction(reason: .invalidCheckpointIdentifier)
            self.listener?.onCheckpointCompleted(
                CheckpointContext.Completed(identifier: identifier, params: params, result: result)
            )
            return result
        }

        let result: CheckpointResult
        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let presentation = CheckpointPresentation(
                workflow: workflow,
                customVariables: params.customVariables
            )
            let outcome = try await self.executor.execute(presentation)
            result = CheckpointResult.PaywallPresented(paywallOutcome: outcome)
        case let .matchedOffering(offering):
            let outcome = try await self.executor.execute(
                offering: offering,
                customVariables: params.customVariables
            )
            result = CheckpointResult.PaywallPresented(paywallOutcome: outcome)
        case let .noAction(reason):
            result = CheckpointResult.NoAction(reason: reason.noActionReason)
        }

        self.listener?.onCheckpointCompleted(
            CheckpointContext.Completed(identifier: identifier, params: params, result: result)
        )
        return result
    }

    @MainActor
    private func gateResult(
        for result: CheckpointResult,
        initialEntitlements: Set<String>
    ) -> CheckpointGateResult {
        switch result {
        case let noAction as CheckpointResult.NoAction:
            return CheckpointGateResult(noActionReason: noAction.reason)
        case let presented as CheckpointResult.PaywallPresented:
            let finalEntitlements: Set<String>
            switch presented.paywallOutcome {
            case let purchased as CheckpointPaywallOutcome.Purchased:
                finalEntitlements = Set(purchased.customerInfo.entitlements.active.keys)
            case let restored as CheckpointPaywallOutcome.Restored:
                finalEntitlements = Set(restored.customerInfo.entitlements.active.keys)
            case let outcome as CheckpointPaywallOutcome.Error:
                return CheckpointGateResult(noActionReason: .error, error: outcome.error)
            default:
                finalEntitlements = Set((self.cachedCustomerInfo()?.entitlements.active ?? [:]).keys)
            }
            return CheckpointGateResult(
                entitlements: finalEntitlements.subtracting(initialEntitlements).sorted().map(EntitlementGrant.init)
            )
        case is CheckpointResult.ReceivedOffering:
            return CheckpointGateResult()
        default:
            let error = NSError(
                domain: "RevenueCat.Checkpoints",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown checkpoint result."]
            )
            return CheckpointGateResult(noActionReason: .error, error: error)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CheckpointResolutionReason {

    var noActionReason: CheckpointNoActionReason {
        switch self {
        case .noMatch:
            return .noMatch
        case .configurationUnavailable:
            return .configurationUnavailable
        case .unknownCheckpoint:
            return .unknownCheckpoint
        }
    }

}
