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

    /// `DispatchTimeInterval` can only be used by specifying a unit of time.
    /// This allows us to easily convert any `DispatchTimeInterval` into nanoseconds.
    /// - Important: It's likely that `x * 1_000_000_000` can't be represented in 32 bits.
    var nanoseconds: UInt64 {
        switch self {
        case let .seconds(s): return UInt64(s) * UInt64(1_000_000_000)
        case let .milliseconds(ms): return UInt64(ms) * UInt64(1_000_000)
        case let .microseconds(ms): return UInt64(ms) * UInt64(1000)
        case let .nanoseconds(ns): return UInt64(ns)
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

    /// - Note: this returns `Int`, so it might lose precision for `.milliseconds` and `.microseconds`.
    var milliseconds: Int {
        switch self {
        case let .seconds(s): return s * 1_000
        case let .milliseconds(ms): return ms
        case let .microseconds(ms): return Int((Double(ms) / 1_000).rounded())
        case let .nanoseconds(ns): return Int((Double(ns) / 1_000_000).rounded())
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

    /// `DispatchTimeInterval` can only be used by specifying a unit of time.
    /// This allows us to easily convert any `DispatchTimeInterval` into seconds.
    var seconds: Double {
        switch self {
        case let .seconds(seconds): return Double(seconds)
        case let .milliseconds(ms): return Double(ms) / 1_000
        case let .microseconds(ms): return Double(ms) / 1_000_000
        case let .nanoseconds(ns): return Double(ns) / 1_000_000_000
        case .never: return 0
        @unknown default: fatalError("Unknown value: \(self)")
        }
    }

}

// swiftlint:enable identifier_name

func + (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> DispatchTimeInterval {
    // Note: `DispatchTimeInterval` uses `Int` for nanoseconds, which might overflow in 32 bits
    // This loses some precision by using milliseconds, but avoids potential overflows.
    return .milliseconds(lhs.milliseconds + rhs.milliseconds)
}

func - (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> DispatchTimeInterval {
    // Note: `DispatchTimeInterval` uses `Int` for nanoseconds, which might overflow in 32 bits
    // This loses some precision by using milliseconds, but avoids potential overflows.
    return .milliseconds(lhs.milliseconds - rhs.milliseconds)
}

extension DispatchTimeInterval: Comparable {

    // swiftlint:disable:next missing_docs
    public static func < (lhs: DispatchTimeInterval, rhs: DispatchTimeInterval) -> Bool {
        return lhs.nanoseconds < rhs.nanoseconds
    }

}

#if swift(<5.9)
// `DispatchTimeInterval` is not `Sendable` as of Swift 5.8.
// Its conformance is safe since it only represents data
// See https://github.com/apple/swift/issues/65044
extension DispatchTimeInterval: @unchecked Sendable {}
#endif
