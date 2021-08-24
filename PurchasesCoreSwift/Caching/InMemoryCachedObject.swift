//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InMemoryCachedObject.swift
//
//  Created by Joshua Liebowitz on 7/13/21.
//

class InMemoryCachedObject<T> {

    var lastUpdatedAt: Date? {
        accessQueue.sync {
            return lastUpdated
        }
    }

    private let accessQueue = DispatchQueue(label: "InMemoryCachedObjectQueue", attributes: .concurrent)
    private var lastUpdated: Date?
    private var cachedObject: T?

    func isCacheStale(durationInSeconds: Double) -> Bool {
        accessQueue.sync {
            guard let lastUpdated = lastUpdated else {
                return true
            }

            let timeSinceLastCheck = -1.0 * lastUpdated.timeIntervalSinceNow
            return timeSinceLastCheck >= durationInSeconds
        }
    }

    func clearCacheTimestamp() {
        accessQueue.executeByLockingDatasource {
            self.lastUpdated = nil
        }
    }

    func clearCache() {
        accessQueue.executeByLockingDatasource {
            self.lastUpdated = nil
            self.cachedObject = nil
        }
    }

    func updateCacheTimestamp(date: Date) {
        accessQueue.executeByLockingDatasource {
            self.lastUpdated = date
        }
    }

    func cache(instance: T) {
        accessQueue.executeByLockingDatasource {
            self.lastUpdated = Date()
            self.cachedObject = instance
        }
    }

    func cachedInstance() -> T? {
        accessQueue.sync {
            return cachedObject
        }
    }

}

private extension DispatchQueue {

    func executeByLockingDatasource<T>(execute work: () throws -> T) rethrows -> T {
        // .barrier is not needed here because we're using `.sync` instead of the normal .async multi-reader
        // single-writer dispatch queue synchronization pattern.
        return try sync(execute: work)
    }

}
