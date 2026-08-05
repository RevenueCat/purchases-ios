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

/// Orchestrates checkpoint resolution, workflow execution, and listener delivery.
final class CheckpointsManager {

    var checkpointListener: CheckpointListener? {
        get { self.listener.value }
        set { self.listener.value = newValue }
    }

    private let listener = Atomic<CheckpointListener?>(nil)
    private var resolver: CheckpointWorkflowResolver
    private let executor: CheckpointWorkflowExecutor

    init(
        resolver: CheckpointWorkflowResolver? = nil,
        executor: CheckpointWorkflowExecutor? = nil,
        presenterProvider: (@MainActor () -> CheckpointPresenter?)? = nil
    ) {
        self.resolver = resolver ?? UnavailableCheckpointWorkflowResolver()
        if let executor {
            self.executor = executor
        } else if let presenterProvider {
            self.executor = UICheckpointWorkflowExecutor(presenterProvider: presenterProvider)
        } else {
            self.executor = UICheckpointWorkflowExecutor()
        }
    }

    func setResolver(_ resolver: CheckpointWorkflowResolver) {
        self.resolver = resolver
    }

    func checkpoint(
        identifier: String,
        params: CheckpointParams?,
        completion: @escaping (Result<CheckpointResult, PublicError>) -> Void
    ) {
        Task { @MainActor in
            do {
                completion(.success(try await self.checkpoint(identifier: identifier, params: params)))
            } catch {
                completion(.failure((error as? PurchasesError)?.asPublicError ?? error as NSError))
            }
        }
    }

    @MainActor
    func checkpoint(identifier: String, params: CheckpointParams?) async throws -> CheckpointResult {
        let checkpoint = CheckpointInfo(
            identifier: identifier,
            params: params ?? CheckpointParams()
        )
        self.checkpointListener?.onCheckpointHit(checkpoint)

        let result: CheckpointResult
        switch await self.resolver.resolve(checkpoint: checkpoint) {
        case let .matched(presentation):
            result = try await self.execute(presentation)
        case let .noMatch(reason):
            result = CheckpointNoActionResult(checkpoint: checkpoint, reason: reason)
        case let .failed(error):
            throw error
        }

        self.checkpointListener?.onCheckpointCompleted(checkpoint, result: result)
        return result
    }

    @MainActor
    private func execute(_ presentation: CheckpointWorkflowPresentation) async throws -> CheckpointResult {
        switch try await self.executor.execute(presentation) {
        case let .paywallFinished(outcome):
            return CheckpointPaywallPresentedResult(
                checkpoint: presentation.checkpoint,
                paywallOutcome: outcome
            )
        }
    }

}

private final class UnavailableCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        return .noMatch(.disabled)
    }

}
