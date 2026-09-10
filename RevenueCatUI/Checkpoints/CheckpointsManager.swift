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

    /// Internal result used by checkpoint gate APIs to distinguish a completed presentation from
    /// a user backing out of its initial workflow step.
    struct CheckpointExecution {
        let result: CheckpointResult
        let didBackOut: Bool
    }

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
        return try await self.executeCheckpoint(identifier: identifier, params: params).result
    }

    @MainActor
    func executeCheckpoint(
        identifier: String,
        params: CheckpointCallParams
    ) async throws -> CheckpointExecution {
        guard CheckpointIdentifierValidator.isValid(identifier) else {
            Logger.error(CheckpointIdentifierValidator.invalidIdentifierLogMessage(identifier))
            let result = CheckpointResult.NoAction(reason: .invalidCheckpointIdentifier)
            return .init(result: result, didBackOut: false)
        }

        let result: CheckpointResult
        let didBackOut: Bool
        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let presentation = CheckpointPresentation(
                workflow: workflow,
                customVariables: params.customVariables
            )
            let execution = try await self.executor.execute(presentation)
            result = CheckpointResult.PaywallPresented(paywallOutcome: execution.outcome)
            didBackOut = execution.didBackOut
        case let .matchedOffering(offering):
            // Data-only, so this never claims the presentation slot the executor owns.
            result = CheckpointResult.ReceivedOffering(offering: offering)
            didBackOut = false
        case let .noAction(reason):
            result = CheckpointResult.NoAction(reason: reason.noActionReason)
            didBackOut = false
        }

        return .init(result: result, didBackOut: didBackOut)
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
