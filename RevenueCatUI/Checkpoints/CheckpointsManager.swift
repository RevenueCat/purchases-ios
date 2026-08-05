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

    typealias ResolveCheckpoint = (String, CheckpointParams) async throws -> CheckpointResolution

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
    private let resolveCheckpoint: ResolveCheckpoint
    private var executor: CheckpointWorkflowExecuting?

    init(
        resolveCheckpoint: @escaping ResolveCheckpoint,
        executor: CheckpointWorkflowExecuting? = nil
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
        case let .workflow(workflow):
            let executor = self.executor ?? CheckpointWorkflowExecutor()
            self.executor = executor
            let outcome = try await executor.execute(workflow)
            result = CheckpointPaywallPresentedResult(
                checkpoint: checkpoint,
                paywallOutcome: outcome
            )
        case let .noAction(reason):
            result = CheckpointNoActionResult(
                checkpoint: checkpoint,
                reason: CheckpointNoActionReason(value: reason.value)
            )
        }

        self.listener?.onCheckpointCompleted(checkpoint, result: result)
        return result
    }

}
