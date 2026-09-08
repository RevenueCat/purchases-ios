//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+Checkpoints.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS) && !targetEnvironment(macCatalyst)

@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
public extension Purchases {

    /// Global listener for checkpoint activity.
    ///
    /// The listener is held by this ``Purchases`` instance and is cleared when the SDK is reconfigured.
    var checkpointListener: CheckpointListener? {
        get { return self.checkpointsManager.listener }
        set { self.checkpointsManager.listener = newValue }
    }

    /// Evaluates a checkpoint and calls `completion` with its result.
    ///
    /// Depending on the configured targeting rules, this may automatically present an experience or return a
    /// ``CheckpointResult/NoAction`` without presenting UI. If an experience is presented, `completion` is called
    /// after the experience finishes.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard. It must start with a letter,
    ///     contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 255 characters.
    ///   - customVariables: Values usable in checkpoint targeting rules, feature events, and the presented paywall.
    ///   - completion: Called with the checkpoint result, or with an error if evaluation or presentation fails.
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        completion: @escaping (Result<CheckpointResult, PublicError>) -> Void
    ) {
        self.checkpointsManager.checkpoint(
            identifier: identifier,
            params: .init(customVariables: customVariables),
            completion: completion
        )
    }

    /// Evaluates a checkpoint and returns its result.
    ///
    /// Depending on the configured targeting rules, this may automatically present an experience or return a
    /// ``CheckpointResult/NoAction`` without presenting UI. If an experience is presented, this method returns
    /// after the experience finishes.
    /// - Parameters:
    ///   - identifier: The checkpoint identifier configured in the RevenueCat dashboard. It must start with a letter,
    ///     contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 255 characters.
    ///   - customVariables: Values usable in checkpoint targeting rules, feature events, and the presented paywall.
    /// - Returns: The result for this checkpoint.
    /// - Throws: An error if checkpoint evaluation or presentation fails.
    @discardableResult
    func checkpoint(
        _ identifier: String,
        customVariables: [String: CustomVariableValue] = [:]
    ) async throws -> CheckpointResult {
        return try await self.checkpointsManager.checkpoint(
            identifier: identifier,
            params: .init(customVariables: customVariables)
        )
    }

}

@available(iOS 15.0, *)
private extension Purchases {

    var checkpointsManager: CheckpointsManager {
        return self.getOrCreateCheckpointsManager {
            self.createCheckpointsManager()
        }
    }

    func createCheckpointsManager() -> CheckpointsManager {
        return CheckpointsManager(resolveCheckpoint: { [weak self] identifier, params in
            guard let self else {
                throw CancellationError()
            }

            return try await self.resolveCheckpoint(identifier: identifier, params: params.coreParams)
        })
    }

}

#endif
