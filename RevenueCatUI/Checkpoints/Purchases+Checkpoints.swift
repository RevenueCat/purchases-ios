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
    var checkpointListener: CheckpointListener? {
        get { return self.checkpointsManager.listener }
        set { self.checkpointsManager.listener = newValue }
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
        self.checkpointsManager.checkpoint(
            identifier: identifier,
            params: params,
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
        return try await self.checkpointsManager.checkpoint(
            identifier: identifier,
            params: params
        )
    }

}

#if ENABLE_CHECKPOINTS_OBJC

@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
public extension Purchases {

    /// Objective-C-compatible checkpoint API.
    @_disfavoredOverload
    @objc(checkpointWithIdentifier:params:completion:)
    func checkpoint(
        _ identifier: String,
        objcParams: ObjCCheckpointParams?,
        completion: @escaping (ObjCCheckpointResult?, PublicError?) -> Void
    ) {
        self.checkpoint(identifier, params: objcParams?.value ?? .init()) { result in
            switch result {
            case let .success(result):
                completion(ObjCCheckpointResult.wrapping(result), nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

}

#endif

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
