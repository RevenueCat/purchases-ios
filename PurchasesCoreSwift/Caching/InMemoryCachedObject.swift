//
//  InMemoryCachedObject.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/13/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

open class InMemoryCachedObject<T> {

    private let accessQueue = DispatchQueue(label: "InMemoryCachedObjectQueue", attributes: .concurrent)
    private var lastUpdated: Date?
    private var cachedObject: T?
    public var lastUpdatedAt: Date? {
        accessQueue.sync {
            return lastUpdated
        }
    }

    public init() { }

    open func isCacheStale(durationInSeconds: Double) -> Bool {
        accessQueue.sync {
            guard let lastUpdated = lastUpdated else {
                return true
            }

            let timeSinceLastCheck = -1.0 * lastUpdated.timeIntervalSinceNow
            return timeSinceLastCheck >= durationInSeconds
        }
    }

    open func clearCacheTimestamp() {
        accessQueue.async(flags: .barrier) {
            self.lastUpdated = nil
        }
    }

    open func clearCache() {
        accessQueue.async(flags: .barrier) {
            self.lastUpdated = nil
            self.cachedObject = nil
        }
    }

    open func updateCacheTimestamp(date: Date) {
        accessQueue.async(flags: .barrier) {
            self.lastUpdated = date
        }
    }

    open func cache(instance: T) {
        accessQueue.async(flags: .barrier) {
            self.cachedObject = instance
        }
    }

    open func cachedInstance() -> T? {
        accessQueue.sync {
            return cachedObject
        }
    }

}
