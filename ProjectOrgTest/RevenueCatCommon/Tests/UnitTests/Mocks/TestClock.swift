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

    var now: Date {
        get { self._now.value }
        set { self._now.value = newValue }
    }
    var currentTime: DispatchTime {
        get { self._currentTime.value }
        set { self._currentTime.value = newValue }
    }

    private let _now: Atomic<Date>
    private let _currentTime: Atomic<DispatchTime>

    init(now: Date = .init(), currentTime: DispatchTime = .now()) {
        self._now = .init(now)
        self._currentTime = .init(currentTime)
    }

}

extension TestClock {

    /// Changes the internal clock by advancing it by `interval`.
    func advance(by interval: DispatchTimeInterval) {
        self.now = self.now.addingTimeInterval(interval.seconds)

        if #available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *) {
            self.currentTime = self.currentTime.advanced(by: interval)
        } else {
            self.currentTime = .init(uptimeNanoseconds: self.currentTime.uptimeNanoseconds + interval.nanoseconds)
        }
    }

}
