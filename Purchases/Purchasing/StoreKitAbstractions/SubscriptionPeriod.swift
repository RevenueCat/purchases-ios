//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionPeriod.swift
//
//  Created by Andrés Boedo on 3/12/21.

import Foundation
import StoreKit

@objc public class SubscriptionPeriod: NSObject {

    public let value: Int
    public let unit: PeriodUnit

    init(value: Int, unit: PeriodUnit) {
        assert(value >= 0, "Invalid value: \(value)")

        self.value = value
        self.unit = unit
    }

    @objc public enum PeriodUnit: Int {

        case unknown = -1
        case day = 0
        case week = 1
        case month = 2
        case year = 3

    }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    static func from(sk1SubscriptionPeriod: SKProductSubscriptionPeriod) -> SubscriptionPeriod {
        return .init(value: sk1SubscriptionPeriod.numberOfUnits,
                     unit: SubscriptionPeriod.PeriodUnit.from(sk1PeriodUnit: sk1SubscriptionPeriod.unit))
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8, *)
    static func from(sk2SubscriptionPeriod: StoreKit.Product.SubscriptionPeriod) -> SubscriptionPeriod {
        return .init(value: sk2SubscriptionPeriod.value,
                     unit: SubscriptionPeriod.PeriodUnit.from(sk2PeriodUnit: sk2SubscriptionPeriod.unit))
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SubscriptionPeriod else { return false }

        return self.value == other.value && self.unit == other.unit
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.value)
        hasher.combine(self.unit)

        return hasher.finalize()
    }

}

extension SubscriptionPeriod.PeriodUnit: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
}

extension SubscriptionPeriod {
    public override var debugDescription: String {
        return "SubscriptionPeriod: \(self.value) \(self.unit)"
    }
}

fileprivate extension SubscriptionPeriod.PeriodUnit {

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    static func from(sk1PeriodUnit: SK1Product.PeriodUnit) -> Self {
        switch sk1PeriodUnit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .unknown
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8, *)
    static func from(sk2PeriodUnit: StoreKit.Product.SubscriptionPeriod.Unit) -> Self {
        switch sk2PeriodUnit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .unknown
        }
    }

}
