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

    /// Creates a `DispatchTimeInterval` from a `TimeInterval` with millisecond precision.
    init(_ timeInterval: TimeInterval) {
        self = .milliseconds(Int(timeInterval * 1000))
    }

    static func days(_ days: Int) -> Self {
        precondition(days >= 0, "Days must be positive: \(days)")

        return .seconds(days * 60 * 60 * 24)
    }

    /// `DispatchTimeInterval` can only be used by specifying a unit of time.
    /// This allows us to easily convert any `DispatchTimeInterval` into nanoseconds.
    var nanoseconds: Int {
        switch self {
        case let .seconds(s): return s * 1_000_000_000
        case let .milliseconds(ms): return ms * 1_000_000
        case let .microseconds(ms): return ms * 1000
        case let .nanoseconds(ns): return ns
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

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

    var days: Double {
        return self.seconds / (60 * 60 * 24)
    }

}

// swiftlint:enable identifier_name

func + (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> DispatchTimeInterval {
    return .nanoseconds(lhs.nanoseconds + rhs.nanoseconds)
}

func - (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> DispatchTimeInterval {
    return .nanoseconds(lhs.nanoseconds - rhs.nanoseconds)
}

extension DispatchTimeInterval: Comparable {

    // swiftlint:disable:next missing_docs
    public static func < (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> Bool {
        return lhs.nanoseconds < rhs.nanoseconds
    }

}

#if swift(<5.8)
// `DispatchTimeInterval` is not `Sendable` as of Swift 5.7.
// Its conformance is safe since it only represents data
extension DispatchTimeInterval: @unchecked Sendable {}
#endif
