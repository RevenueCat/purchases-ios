//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+Checkpoint.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

@_spi(Internal) public extension Purchases {

    /// Global listener for checkpoint activity.
    var checkpointListener: CheckpointListener? {
        get { return (self.checkpointEngineListener as? CheckpointListenerAdapter)?.listener }
        set { self.checkpointEngineListener = newValue.map(CheckpointListenerAdapter.init) }
    }

    /// Registers that a checkpoint was hit.
    ///
    /// Depending on the configured targeting rules, this may auto-present an experience or do nothing.
    /// The call resolves when the experience finishes.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard.
    ///   - params: Optional per-call parameters.
    ///   - completion: Called with the result, or an error if the checkpoint could not be handled.
    func checkpoint(
        _ identifier: String,
        params: CheckpointParams = .init(),
        completion: @escaping (Result<CheckpointResult, PublicError>) -> Void
    ) {
        self.performCheckpoint(
            identifier: identifier,
            params: params,
            presenter: nil
        ) { result in
            completion(result.map(CheckpointResult.from))
        }
    }

    /// Registers that a checkpoint was hit.
    ///
    /// Depending on the configured targeting rules, this may auto-present an experience or do nothing.
    /// The call resolves when the experience finishes.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard.
    ///   - params: Optional per-call parameters.
    /// - Returns: The result for this checkpoint.
    /// - Throws: An error if the checkpoint could not be handled.
    func checkpoint(
        _ identifier: String,
        params: CheckpointParams = .init()
    ) async throws -> CheckpointResult {
        return CheckpointResult.from(
            try await self.performCheckpoint(
                identifier: identifier,
                params: params,
                presenter: nil
            )
        )
    }

}

private final class CheckpointListenerAdapter: CheckpointEngineListener {

    let listener: CheckpointListener

    init(listener: CheckpointListener) {
        self.listener = listener
    }

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        self.listener.onCheckpointHit(checkpoint)
    }

    func onCheckpointResolved(_ checkpoint: CheckpointInfo, result: CheckpointEngineResult) {
        self.listener.onCheckpointResolved(
            checkpoint,
            result: CheckpointResult.from(result)
        )
    }

    func onCheckpointPaywallFinished(
        _ checkpoint: CheckpointInfo,
        outcome: CheckpointEnginePaywallOutcome
    ) {
        self.listener.onCheckpointPaywallFinished(
            checkpoint,
            outcome: CheckpointPaywallOutcome.from(outcome)
        )
    }

}
