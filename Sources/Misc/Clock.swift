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
protocol ClockType {

    var now: Date { get }

}

/// Default implementation of `ClockType` which simply provides the current date.
final class Clock: ClockType {

    var now: Date { return Date() }

    static let `default`: Clock = .init()

}
