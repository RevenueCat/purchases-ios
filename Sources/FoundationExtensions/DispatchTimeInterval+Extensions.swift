//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DispatchTimeInterval+Extensions.swift
//
//  Created by Nacho Soto on 12/2/21.

// swiftlint:disable identifier_name
import Foundation

extension DispatchTimeInterval {

    /// `DispatchTimeInterval` can only be used by specifying a unit of time.
    /// This allows us to easily convert any `DispatchTimeInterval` into seconds.
    var seconds: Double {
        switch self {
        case let .seconds(seconds): return Double(seconds)
        case let .milliseconds(ms): return Double(ms) / 1000
        case let .microseconds(ms): return Double(ms) / 1_000_000
        case let .nanoseconds(ns): return Double(ns) / 1_000_000_000
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

    fileprivate var milliseconds: Double {
        switch self {
        case let .seconds(seconds): return Double(seconds * 1000)
        case let .milliseconds(ms): return Double(ms)
        case let .microseconds(ms): return Double(ms) / 1_000
        case let .nanoseconds(ns): return Double(ns) / 1_000_000
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

}

// swiftlint:enable identifier_name

func + (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> DispatchTimeInterval {
    return .milliseconds(Int(lhs.milliseconds + rhs.milliseconds))
}
