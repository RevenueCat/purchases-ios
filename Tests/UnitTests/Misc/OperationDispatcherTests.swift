//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperationDispatcherTests.swift
//
//  Created by Nacho Soto on 9/7/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class OperationDispatcherTests: TestCase {

    func testDelayForBackgroundedApp() {
        expect(JitterableDelay.default(forBackgroundedApp: true)) == .default
    }

    func testDelayForForegroundedApp() {
        expect(JitterableDelay.default(forBackgroundedApp: false)) == JitterableDelay.none
    }

    func testNoDelay() {
        expect(JitterableDelay.none.hasDelay) == false
        expect(JitterableDelay.none.range) == 0..<0
    }

    func testDefaultDelay() {
        expect(JitterableDelay.default.hasDelay) == true
        expect(JitterableDelay.default.range) == 0..<5
    }

    func testLongDelay() {
        expect(JitterableDelay.long.hasDelay) == true
        expect(JitterableDelay.long.range) == 5..<10
    }

}
