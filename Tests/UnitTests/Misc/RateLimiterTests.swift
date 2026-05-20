//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RateLimiterTests.swift
//
//  Created by Josh Holtz on 2/27/24.

import Nimble
import XCTest

@testable import RevenueCat

class RateLimiterTests: TestCase {

    func testAllowsCorrectNumberOfCalls() {
        let rateLimiter = RateLimiter(maxCalls: 2, period: 1)

        expect(rateLimiter.shouldProceed()) == true
        expect(rateLimiter.shouldProceed()) == true
    }

    func testBlocksExcessCalls() {
        let rateLimiter = RateLimiter(maxCalls: 1, period: 2)

        expect(rateLimiter.shouldProceed()) == true
        expect(rateLimiter.shouldProceed()) == false
    }

    func testResetsAfterPeriod() {
        let rateLimiter = RateLimiter(maxCalls: 1, period: 2)

        expect(rateLimiter.shouldProceed()) == true
        sleep(2)
        expect(rateLimiter.shouldProceed()) == true
    }

}
