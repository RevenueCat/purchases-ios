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
    private let resolveCheckpoint: (String, CheckpointParams) async throws -> CheckpointResolution
    @MainActor private lazy var executor: CheckpointExecutor = CheckpointWorkflowExecutor()

    init(resolveCheckpoint: @escaping (String, CheckpointParams) async throws -> CheckpointResolution) {
        self.resolveCheckpoint = resolveCheckpoint
    }

    @MainActor
    init(
        resolveCheckpoint: @escaping (String, CheckpointParams) async throws -> CheckpointResolution,
        executor: CheckpointExecutor
    ) {
        self.resolveCheckpoint = resolveCheckpoint
        self.executor = executor
    }

    func checkpoint(
        identifier: String,
        params: CheckpointParams,
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
        params: CheckpointParams
    ) async throws -> CheckpointResult {
        let checkpoint = CheckpointInfo(identifier: identifier, params: params)
        self.listener?.onCheckpointHit(checkpoint)

        let result: CheckpointResult
        switch try await self.resolveCheckpoint(identifier, params) {
        case let .matchedWorkflow(workflow):
            let outcome = try await self.executor.execute(workflow)
            result = CheckpointPaywallPresentedResult(
                checkpoint: checkpoint,
                paywallOutcome: outcome
            )
        case let .matchedOffering(offering):
            // Data-only, so this never claims the presentation slot the executor owns.
            result = CheckpointReceivedOfferingResult(
                checkpoint: checkpoint,
                offering: offering
            )
        case let .noAction(reason):
            result = CheckpointNoActionResult(
                checkpoint: checkpoint,
                reason: reason.noActionReason
            )
        }

        self.listener?.onCheckpointCompleted(checkpoint, result: result)
        return result
    }

}

private extension CheckpointResolutionReason {

    var noActionReason: CheckpointNoActionReason {
        switch self {
        case .noMatch:
            return .noMatch
        case .configurationUnavailable:
            return .configurationUnavailable
        case .disabled:
            return .disabled
        case .unknownCheckpoint:
            return .unknownCheckpoint
        }
    }

}
