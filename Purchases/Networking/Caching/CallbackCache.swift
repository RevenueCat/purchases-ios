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
 Users of this class will have determined that an API call is running and they will store a completion block from
 the next API call that will no longer run. Once the first API call has finished, the user is required to call
 `performOnAllItemsAndRemoveFromCache`. This way the results from the initial API call will be surfaced to the waiting
 completion blocks from the duplicate API calls that were not sent, and then removed from the cache.
 */
class CallbackCache<T> where T: Cachable {

    private var cachedCallbacksByKey: [String: [T]] = [:]
    private let callbackQueue: DispatchQueue

    init(callbackQueue: DispatchQueue) {
        self.callbackQueue = callbackQueue
    }

    func add(callback: T) -> CallbackCacheStatus {
        callbackQueue.sync {
            var values = cachedCallbacksByKey[callback.key] ?? []
            let cacheStatus: CallbackCacheStatus = !values.isEmpty ?
                .addedToExistingInFlightList :
                .firstCallbackAddedToList

            values.append(callback)
            cachedCallbacksByKey[callback.key] = values
            return cacheStatus
        }
    }

    func performOnAllItemsAndRemoveFromCache(withCacheable cacheable: Cachable, _ block: (T) -> Void) {
        callbackQueue.sync {
            guard let items = cachedCallbacksByKey[cacheable.key] else {
                return
            }

            items.forEach { block($0) }
            cachedCallbacksByKey.removeValue(forKey: cacheable.key)
        }
    }

}

protocol Cachable {

    var key: String { get }

}
