//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DispatchTimeIntervalExtensionsTests.swift
//
//  Created by Nacho Soto on 3/16/23.

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable identifier_name

class DispatchTimeIntervalExtensionsTests: TestCase {

    func testIsLessThan() {
        let a: DispatchTimeInterval = .seconds(1)
        let b: DispatchTimeInterval = .seconds(2)

        expect(a) < b
    }

    func testIsGreaterThan() {
        let a: DispatchTimeInterval = .seconds(2)
        let b: DispatchTimeInterval = .seconds(1)

        expect(a) > b
    }

    func testSecondsToMilliseconds() {
        expect(DispatchTimeInterval.seconds(5).milliseconds) == 5_000
    }

    func testSecondsToNanoseconds() {
        expect(DispatchTimeInterval.seconds(5).nanoseconds) == 5_000_000_000
    }

    func testAddingSeconds() {
        let a: DispatchTimeInterval = .seconds(2)
        let b: DispatchTimeInterval = .seconds(1)

        expect(a + b) == .seconds(3)
    }

    func testAddingMilliseconds() {
        let a: DispatchTimeInterval = .milliseconds(2)
        let b: DispatchTimeInterval = .milliseconds(1)

        expect(a + b) == .milliseconds(3)
    }

    func testAddingNanoseconds() {
        let a: DispatchTimeInterval = .nanoseconds(2_000_000)
        let b: DispatchTimeInterval = .nanoseconds(1_000_000)

        expect(a + b) == .milliseconds(3)
    }

    func testSubstractingSeconds() {
        let a: DispatchTimeInterval = .seconds(3)
        let b: DispatchTimeInterval = .seconds(1)

        expect(a - b) == .seconds(2)
    }

    func testSubstractingMilliseconds() {
        let a: DispatchTimeInterval = .milliseconds(3)
        let b: DispatchTimeInterval = .milliseconds(1)

        expect(a - b) == .milliseconds(2)
    }

    func testSubstractingNanoseconds() {
        let a: DispatchTimeInterval = .nanoseconds(3_000_000)
        let b: DispatchTimeInterval = .nanoseconds(1_000_000)

        expect(a - b) == .milliseconds(2)
    }

}
