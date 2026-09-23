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
    var appUserID: String
    var source: NetworkOperation.Type
    var completion: Completion

    init<T: CacheableNetworkOperation>(cacheKey: String,
                                       appUserID: String,
                                       source: T.Type,
                                       completion: @escaping Completion) {
        self.cacheKey = cacheKey
        self.appUserID = appUserID
        self.source = T.self
        self.completion = completion
    }

}

// MARK: - CallbackCache helpers

extension CallbackCache where T == CustomerInfoCallback {

    /// Appends the callback to an in-flight `PostReceiptDataOperation` for the same user if there is one,
    /// since its response will contain up to date `CustomerInfo`. Receipt posts for other users are ignored:
    /// their `CustomerInfo` must never be surfaced as `callback.appUserID`'s.
    func addOrAppendToPostReceiptDataOperation(callback: CustomerInfoCallback) -> CallbackCacheStatus {
        if let existing = self.callbacks(ofType: PostReceiptDataOperation.self, appUserID: callback.appUserID).last {
            return self.add(callback.withNewCacheKey(existing.cacheKey))
        } else {
            return self.add(callback)
        }
    }

    private func callbacks(ofType type: NetworkOperation.Type, appUserID: String) -> [T] {
        return self
            .cachedCallbacksByKey
            .lazy
            .flatMap(\.value)
            .filter { $0.source == type && $0.appUserID == appUserID }
    }

}

private extension CustomerInfoCallback {

    func withNewCacheKey(_ newKey: String) -> Self {
        var copy = self
        copy.cacheKey = newKey

        return copy
    }

}
