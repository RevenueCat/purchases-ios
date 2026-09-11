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

    private let resolveCheckpoint: (String, CheckpointCallParams) async throws -> CheckpointResolution
    @MainActor private lazy var executor: CheckpointExecutor = CheckpointWorkflowExecutor()

    init(resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution) {
        self.resolveCheckpoint = resolveCheckpoint
    }

    @MainActor
    init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        executor: CheckpointExecutor
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.executor = executor
    }

    func checkpoint(
        identifier: String,
        params: CheckpointCallParams,
        completion: @escaping (Result<CheckpointResult, PublicError>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(
                    .success(
                        try await self.checkpoint(
                            identifier: identifier,
                            params: params
                        )
                    )
                )
            } catch {
                completion(.failure(error as NSError))
            }
        }
    }

    @MainActor
    func checkpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointResult {
        return try await self.executeCheckpoint(identifier: identifier, params: params).value
    }

    @MainActor
    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointExecutionResult<CheckpointResult> {
        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            return .completed(CheckpointResult.NoAction(reason: .invalidCheckpointIdentifier))
        }

        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let presentation = CheckpointPresentation(
                workflow: workflow,
                customVariables: params.customVariables
            )
            return try await self.executor.execute(presentation).map {
                CheckpointResult.PaywallPresented(paywallOutcome: $0)
            }
        case let .matchedOffering(offering):
            // Data-only, so this never claims the presentation slot the executor owns.
            return .completed(CheckpointResult.ReceivedOffering(offering: offering))
        case let .noAction(reason):
            return .completed(CheckpointResult.NoAction(reason: reason.noActionReason))
        }
    }

    @MainActor
    func checkpointForCallback(
        identifier: String,
        params: CheckpointCallParams
    ) async -> CheckpointCallbackResult {
        do {
            switch try await self.executeCheckpoint(identifier: identifier, params: params) {
            case .backedOut:
                return .suppressed
            case let .completed(result):
                guard let presented = result as? CheckpointResult.PaywallPresented else {
                    return .completed(nil)
                }
                return .completed(self.flowResult(for: presented.paywallOutcome))
            }
        } catch CheckpointError.operationAlreadyInProgress {
            return .suppressed
        } catch {
            return .completed(nil)
        }
    }

    @MainActor
    private func flowResult(for outcome: CheckpointPaywallOutcome) -> CheckpointFlowResult? {
        let entitlements: [EntitlementInfo]
        switch outcome {
        case let purchased as CheckpointPaywallOutcome.Purchased:
            entitlements = Array(purchased.customerInfo.entitlements.active.values)
        case let restored as CheckpointPaywallOutcome.Restored:
            entitlements = Array(restored.customerInfo.entitlements.active.values)
        case is CheckpointPaywallOutcome.Error:
            return nil
        default:
            entitlements = []
        }

        return CheckpointFlowResult(
            obtainedEntitlements: Set(entitlements.map(CheckpointObtainedEntitlement.init))
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointCallbackResult {
    case completed(CheckpointFlowResult?)
    case suppressed
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
