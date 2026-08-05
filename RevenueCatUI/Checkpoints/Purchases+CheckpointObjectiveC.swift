//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+CheckpointObjectiveC.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if ENABLE_CHECKPOINTS_OBJC

@_spi(Internal) public extension Purchases {

    /// Objective-C-compatible checkpoint API.
    @_disfavoredOverload
    @objc(checkpointWithIdentifier:params:completion:)
    func checkpoint(
        _ identifier: String,
        params: ObjCCheckpointParams?,
        completion: @escaping (ObjCCheckpointResult?, PublicError?) -> Void
    ) {
        self.checkpoint(identifier, params: params?.swiftValue ?? .init()) { result in
            switch result {
            case let .success(result):
                completion(.wrapping(result), nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

}

#endif
