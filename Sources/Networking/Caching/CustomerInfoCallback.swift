//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoCallback.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

struct CustomerInfoCallback: CacheKeyProviding {

    typealias Completion = (Result<CustomerInfo, BackendError>) -> Void

    var cacheKey: String
    var source: NetworkOperation.Type
    var completion: Completion

    init<T: CacheableNetworkOperation>(cacheKey: String,
                                       source: T.Type,
                                       completion: @escaping Completion) {
        self.cacheKey = cacheKey
        self.source = T.self
        self.completion = completion
    }

}

// MARK: - CallbackCache helpers

extension CallbackCache where T == CustomerInfoCallback {

    func addOrAppendToPostReceiptDataOperation(callback: CustomerInfoCallback) -> CallbackCacheStatus {
        if let existing = self.callbacks(ofType: PostReceiptDataOperation.self).last {
            return self.add(callback.withNewCacheKey(existing.cacheKey))
        } else {
            return self.add(callback)
        }
    }

    private func callbacks(ofType type: NetworkOperation.Type) -> [T] {
        return self
            .cachedCallbacksByKey
            .lazy
            .flatMap(\.value)
            .filter { $0.source == type }
    }

}

private extension CustomerInfoCallback {

    func withNewCacheKey(_ newKey: String) -> Self {
        var copy = self
        copy.cacheKey = newKey

        return copy
    }

}
