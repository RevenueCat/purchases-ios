//
//  InMemoryCachedObject.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/13/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

class InMemoryCachedObject<T> {

    private let accessQueue = DispatchQueue(label: "InMemoryCachedObjectQueue", attributes: .concurrent)
    private var lastUpdated: Date?
    private var cachedObject: T?
    public var lastUpdatedAt: Date? {
        accessQueue.sync {
            return lastUpdated
        }
    }

    public init() { }

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
        accessQueue.sync(flags: .barrier) {
            self.lastUpdated = nil
        }
    }

    func clearCache() {
        accessQueue.sync(flags: .barrier) {
            self.lastUpdated = nil
            self.cachedObject = nil
        }
    }

    func updateCacheTimestamp(date: Date) {
        accessQueue.sync(flags: .barrier) {
            self.lastUpdated = date
        }
    }

    func cache(instance: T) {
        accessQueue.sync(flags: .barrier) {
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
