//
//  InMemoryCachedObject.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/13/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

public class InMemoryCachedObject<T> {

    public var lastUpdatedAt: Date? {
        accessQueue.sync {
            return lastUpdated
        }
    }

    private let accessQueue = DispatchQueue(label: "InMemoryCachedObjectQueue", attributes: .concurrent)
    private var lastUpdated: Date?
    private var cachedObject: T?

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
