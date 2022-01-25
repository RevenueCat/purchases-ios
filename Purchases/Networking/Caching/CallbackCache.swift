//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CallbackCache.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

/**
 Generic callback cache whose primary usage is to help ensure API calls in flight are not duplicated.
 Users of this class will store a completion block for any Cacheable API call that is running. If the same request is
 made while a request is in-flight, the completion block will be added to the list and the API call will not be
 performed. Once the first API call has finished, the user is required to call `performOnAllItemsAndRemoveFromCache`.
 This way the results from the initial API call will be surfaced to the waiting completion blocks from the duplicate
 API calls that were not sent. After being called these blocks are removed from the cache.
 */
class CallbackCache<T> where T: CacheKeyProviding {

    private var cachedCallbacksByKey: [String: [T]] = [:]
    private let callbackQueue: DispatchQueue

    init(callbackQueue: DispatchQueue) {
        self.callbackQueue = callbackQueue
    }

    func add(callback: T) -> CallbackCacheStatus {
        callbackQueue.sync {
            var values = cachedCallbacksByKey[callback.cacheKey] ?? []
            let cacheStatus: CallbackCacheStatus = !values.isEmpty ?
                .addedToExistingInFlightList :
                .firstCallbackAddedToList

            values.append(callback)
            cachedCallbacksByKey[callback.cacheKey] = values
            return cacheStatus
        }
    }

    func performOnAllItemsAndRemoveFromCache(withCacheable cacheable: CacheKeyProviding, _ block: (T) -> Void) {
        callbackQueue.sync {
            guard let items = cachedCallbacksByKey[cacheable.cacheKey] else {
                return
            }

            items.forEach { block($0) }
            cachedCallbacksByKey.removeValue(forKey: cacheable.cacheKey)
        }
    }

}

protocol CacheKeyProviding {

    var cacheKey: String { get }

}
