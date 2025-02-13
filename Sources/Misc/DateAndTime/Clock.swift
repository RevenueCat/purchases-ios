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

// swiftlint:disable missing_docs
@_spi(Internal) public protocol ClockType: Sendable {

    var now: Date { get }
    var currentTime: DispatchTime { get }

}

@_spi(Internal) public final class Clock: ClockType {

    @_spi(Internal) public var now: Date { return Date() }
    @_spi(Internal) public var currentTime: DispatchTime { return .now() }

    @_spi(Internal) public static let `default`: Clock = .init()

}
// swiftlint:enable missing_docs

extension ClockType {

    func durationSince(_ startTime: DispatchTime) -> TimeInterval {
        return startTime.distance(to: self.currentTime).seconds
    }

    func durationSince(_ date: Date) -> TimeInterval {
        return date.distance(to: self.now)
    }

}
