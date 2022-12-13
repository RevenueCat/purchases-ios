//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestClock.swift
//
//  Created by Nacho Soto on 12/13/22.

import Foundation

@testable import RevenueCat

/// `ClockType` implementation which can be used to mock time.
/// By default, it's initialized with the current time, and that becomes frozen until modified.
final class TestClock: ClockType {

    var now: Date

    init() { self.now = Date() }

}

extension TestClock {

    /// Changes the internal clock by advancing it by `interval`.
    func advance(by interval: DispatchTimeInterval) {
        self.now = self.now.addingTimeInterval(interval.seconds)
    }

}
