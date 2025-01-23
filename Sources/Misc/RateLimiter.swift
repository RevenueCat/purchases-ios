//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RateLimiter.swift
//
//  Created by Josh Holtz on 2/27/24.

import Foundation

internal final class RateLimiter: @unchecked Sendable {
    private let lock = Lock()
    private var timestamps: [Date?]
    private var index: Int = 0
    private let maxCallsInclusive: Int

    let maxCalls: Int
    let period: TimeInterval

    init(maxCalls: Int, period: TimeInterval) {
        self.maxCalls = maxCalls
        self.maxCallsInclusive = self.maxCalls + 1
        self.period = period

        self.timestamps = Array(repeating: nil, count: maxCallsInclusive)
    }

    func shouldProceed() -> Bool {
        return self.lock.perform {
            let now = Date()
            let oldestIndex = (index + 1) % maxCallsInclusive
            let oldestTimestamp = timestamps[oldestIndex]

            // Check if the oldest timestamp is outside the rate limiting period or if it's nil
            if let oldestTimestamp = oldestTimestamp, now.timeIntervalSince(oldestTimestamp) <= period {
                return false
            } else {
                timestamps[index] = now
                index = oldestIndex
                return true
            }
        }
    }
}
