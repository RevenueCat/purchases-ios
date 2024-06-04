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

import Foundation

class InMemoryCachedObject<T> {

    private typealias Data = (cachedObject: T?, lastUpdated: Date?)

    private let content: Atomic<Data> = .init((nil, nil))

    var lastUpdatedAt: Date? {
        return self.content.value.lastUpdated
    }

    func isCacheStale(durationInSeconds: Double) -> Bool {
        return self.content.withValue {
            guard let lastUpdated = $0.lastUpdated else {
                return true
            }

            let timeSinceLastCheck = -1.0 * lastUpdated.timeIntervalSinceNow
            return timeSinceLastCheck >= durationInSeconds
        }
    }

    func clearCacheTimestamp() {
        self.content.modify { $0.lastUpdated = nil }
    }

    func clearCache() {
        self.content.modify {
            $0.cachedObject = nil
            $0.lastUpdated = nil
        }
    }

    func updateCacheTimestamp(date: Date) {
        self.content.modify {
            $0.lastUpdated = date
        }
    }

    func cache(instance: T) {
        self.content.modify {
            $0.lastUpdated = Date()
            $0.cachedObject = instance
        }
    }

    var cachedInstance: T? {
        return self.content.value.cachedObject
    }
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension InMemoryCachedObject: @unchecked Sendable {}
