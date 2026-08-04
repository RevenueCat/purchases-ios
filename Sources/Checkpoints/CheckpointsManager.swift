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

/// Placeholder backing the checkpoint API surface until the implementation lands.
final class CheckpointsManager {

    var checkpointListener: CheckpointListener? {
        get { self.listener.value }
        set { self.listener.value = newValue }
    }

    private let listener = Atomic<CheckpointListener?>(nil)

    func checkpoint(
        identifier: String,
        params: CheckpointParams?,
        completion: @escaping (Result<CheckpointResult, PublicError>) -> Void
    ) {
        completion(.failure(Self.unsupportedError.asPublicError))
    }

    func checkpoint(identifier: String, params: CheckpointParams?) async throws -> CheckpointResult {
        throw Self.unsupportedError
    }

    private static var unsupportedError: PurchasesError {
        return PurchasesError(
            error: .unsupportedError,
            userInfo: [NSLocalizedDescriptionKey: "Checkpoints are not implemented yet."]
        )
    }

}
