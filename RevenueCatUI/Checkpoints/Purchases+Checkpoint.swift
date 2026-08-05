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
        get { return self.checkpointListenerInternal }
        set { self.checkpointListenerInternal = newValue }
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
            presenter: nil,
            completion: completion
        )
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
        return try await self.performCheckpoint(
            identifier: identifier,
            params: params,
            presenter: nil
        )
    }

}
