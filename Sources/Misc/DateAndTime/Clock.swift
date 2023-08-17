//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Clock.swift
//
//  Created by Nacho Soto on 12/13/22.

import Foundation

/// A type that can provide the current `Date`
protocol ClockType: Sendable {

    var now: Date { get }
    var currentTime: DispatchTime { get }

}

/// Default implementation of `ClockType` which simply provides the current date.
final class Clock: ClockType {

    var now: Date { return Date() }
    var currentTime: DispatchTime { return .now() }

    static let `default`: Clock = .init()

}

extension ClockType {

    func durationSince(_ startTime: DispatchTime) -> TimeInterval {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            return startTime.distance(to: self.currentTime).seconds
        } else {
            return TimeInterval(self.currentTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        }
    }

    func durationSince(_ date: Date) -> TimeInterval {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            return date.distance(to: self.now)
        } else {
            return date.timeIntervalSince(self.now)
        }
    }

}
