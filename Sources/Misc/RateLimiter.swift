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

internal class RateLimiter {
    private var timestamps: [Date] = []

    let maxCalls: Int
    let period: TimeInterval // Period in seconds

    init(maxCalls: Int, period: TimeInterval) {
        self.maxCalls = maxCalls
        self.period = period
    }

    func shouldProceed() -> Bool {
        let now = Date()
        timestamps = timestamps.filter { now.timeIntervalSince($0) <= period }

        if timestamps.count < maxCalls {
            timestamps.append(now)
            return true
        } else {
            return false
        }
    }
}
