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

/// A type that can provide the current `Date` and `DispatchTime`.
///
/// - Note: Internal use only
@_spi(Internal) public protocol ClockType: Sendable {

    /// This property provides the current date as a `Date` object.
    var now: Date { get }

    /// the current time using `DispatchTime`, which is useful for performance measurement or time-sensitive operations
    /// in GCD contexts.
    var currentTime: DispatchTime { get }

}

/// Default implementation of `ClockType` which simply provides the current date.
@_spi(Internal) public final class Clock: ClockType {

    /// Returns the current date.
    @_spi(Internal) public var now: Date { return Date() }

    /// Returns the current time as a `DispatchTime`.
    @_spi(Internal) public var currentTime: DispatchTime { return .now() }

    /// Default instance of `Clock` for convenience.
    @_spi(Internal) public static let `default`: Clock = .init()

}

extension ClockType {

    func durationSince(_ startTime: DispatchTime) -> TimeInterval {
        return startTime.distance(to: self.currentTime).seconds
    }

    func durationSince(_ date: Date) -> TimeInterval {
        return date.distance(to: self.now)
    }

}
