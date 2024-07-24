//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimeInterval+ExtensionsTests.swift
//
//  Created by Will Taylor on 7/12/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class TimeIntervalExtensionsTests: TestCase {

    func testTimeIntervalMillisecondsInitializerOneSecond() {
        let timeInterval = TimeInterval(milliseconds: 1000)
        expect(timeInterval).to(equal(1))
    }

    func testTimeIntervalMillisecondsInitializerHalfSecond() {
        let timeInterval = TimeInterval(milliseconds: 500)
        expect(timeInterval).to(equal(0.5))
    }
}
