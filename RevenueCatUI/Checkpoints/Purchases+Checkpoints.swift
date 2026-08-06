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

@_spi(Internal) public extension Purchases {

    /// Global listener for checkpoint activity.
    var checkpointListener: CheckpointListener? {
        get { return self.checkpointCoordinator.listener }
        set { self.checkpointCoordinator.listener = newValue }
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
        completion(.failure(Self.checkpointUnavailableError))
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
        throw Self.checkpointUnavailableError
    }

}

#if ENABLE_CHECKPOINTS_OBJC
@_spi(Internal) public extension Purchases {

    /// Objective-C-compatible checkpoint API.
    @_disfavoredOverload
    @objc(checkpointWithIdentifier:params:completion:)
    func checkpoint(
        _ identifier: String,
        params: CheckpointParams?,
        completion: @escaping (CheckpointResult?, PublicError?) -> Void
    ) {
        self.checkpoint(identifier, params: params ?? .init()) { result in
            switch result {
            case let .success(result):
                completion(result, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

}
#endif

private extension Purchases {

    var checkpointCoordinator: CheckpointCoordinator {
        if let coordinator = self.checkpointCoordinatorObject as? CheckpointCoordinator {
            return coordinator
        }

        let coordinator = CheckpointCoordinator()
        self.checkpointCoordinatorObject = coordinator
        return coordinator
    }

    static var checkpointUnavailableError: PublicError {
        return NSError(
            domain: "RevenueCat.Checkpoints",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Checkpoints are not implemented yet."]
        )
    }

}

private final class CheckpointCoordinator {

    var listener: CheckpointListener?

}
