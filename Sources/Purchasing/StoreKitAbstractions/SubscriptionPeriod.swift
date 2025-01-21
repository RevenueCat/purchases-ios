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

/// The duration of time between subscription renewals.
/// Use the value and the unit together to determine the subscription period.
/// For example, if the unit is  `.month`, and the value is `3`, the subscription period is three months.
@objc(RCSubscriptionPeriod)
public final class SubscriptionPeriod: NSObject {

    /// The number of period units.
    @objc public let value: Int
    /// The increment of time that a subscription period is specified in.
    @objc public let unit: Unit

    /// Creates a new ``SubscriptionPeriod`` with the given value and unit.
    public init(value: Int, unit: Unit) {
        assert(value > 0, "Invalid value: \(value)")

        self.value = value
        self.unit = unit
    }

    /// Units of time used to describe subscription periods.
    @objc(RCSubscriptionPeriodUnit)
    public enum Unit: Int {

        /// A subscription period unit of a day.
        case day = 0
        /// A subscription period unit of a week.
        case week = 1
        /// A subscription period unit of a month.
        case month = 2
        /// A subscription period unit of a year.
        case year = 3

    }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    static func from(sk1SubscriptionPeriod: SKProductSubscriptionPeriod) -> SubscriptionPeriod? {
        guard let unit = SubscriptionPeriod.Unit.from(sk1PeriodUnit: sk1SubscriptionPeriod.unit) else {
            return nil
        }

        return .init(value: sk1SubscriptionPeriod.numberOfUnits, unit: unit)
            .normalized()
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8, *)
    static func from(sk2SubscriptionPeriod: StoreKit.Product.SubscriptionPeriod) -> SubscriptionPeriod? {
        guard let unit = SubscriptionPeriod.Unit.from(sk2PeriodUnit: sk2SubscriptionPeriod.unit) else {
            return nil
        }

        return .init(value: sk2SubscriptionPeriod.value, unit: unit)
            .normalized()
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

// MARK: - Renames

// @available annotations to help users migrating from `SKProductSubscriptionPeriod` to `SubscriptionPeriod`
public extension SubscriptionPeriod {

    /// The number of units per subscription period
    @available(iOS, unavailable, renamed: "value")
    @available(tvOS, unavailable, renamed: "value")
    @available(watchOS, unavailable, renamed: "value")
    @available(macOS, unavailable, renamed: "value")
    @objc var numberOfUnits: Int { fatalError() }

}

extension SubscriptionPeriod.Unit: Sendable {}
extension SubscriptionPeriod: Sendable {}

public extension SubscriptionPeriod {

    /// The length of the period convert to another unit
    func numberOfUnitsAs(unit: Unit) -> Decimal {
        switch unit {
        case .day:
            return Decimal(self.value) * self.unitsPerDay
        case .week:
            return Decimal(self.value) * self.unitsPerWeek
        case .month:
            return Decimal(self.value) * self.unitsPerMonth
        case .year:
            return Decimal(self.value) * self.unitsPerYear
        }
    }

}

extension SubscriptionPeriod {

    func pricePerDay(withTotalPrice price: Decimal) -> Decimal {
        return self.pricePerPeriod(for: self.unitsPerDay, totalPrice: price)
    }

    func pricePerWeek(withTotalPrice price: Decimal) -> Decimal {
        return self.pricePerPeriod(for: self.unitsPerWeek, totalPrice: price)
    }

    func pricePerMonth(withTotalPrice price: Decimal) -> Decimal {
        return self.pricePerPeriod(for: self.unitsPerMonth, totalPrice: price)
    }

    func pricePerYear(withTotalPrice price: Decimal) -> Decimal {
        return self.pricePerPeriod(for: self.unitsPerYear, totalPrice: price)
    }

    private var unitsPerDay: Decimal {
        switch self.unit {
        case .day: return 1
        case .week: return Constants.daysPerWeek
        case .month: return Constants.daysPerMonth
        case .year: return Constants.daysPerYear
        }
    }

    private var unitsPerWeek: Decimal {
        switch self.unit {
        case .day: return 1 / Constants.daysPerWeek
        case .week: return 1
        case .month: return Constants.weeksPerMonth
        case .year: return Constants.weeksPerYear
        }
    }

    private var unitsPerMonth: Decimal {
        switch self.unit {
        case .day: return 1 / Constants.daysPerMonth
        case .week: return 1 / Constants.weeksPerMonth
        case .month: return 1
        case .year: return Constants.monthsPerYear
        }
    }

    private var unitsPerYear: Decimal {
        switch self.unit {
        case .day: return 1 / Constants.daysPerYear
        case .week: return 1 / Constants.weeksPerYear
        case .month: return 1 / Constants.monthsPerYear
        case .year: return 1
        }
    }

    private func pricePerPeriod(for units: Decimal, totalPrice: Decimal) -> Decimal {
        let periods: Decimal = units * Decimal(self.value)

        return (totalPrice as NSDecimalNumber)
            .dividing(by: periods as NSDecimalNumber,
                      withBehavior: Self.roundingBehavior) as Decimal
    }

    private static let roundingBehavior = NSDecimalNumberHandler(
        roundingMode: .plain,
        scale: 2,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )

}

private extension SubscriptionPeriod {

    enum Constants {
        static let daysPerWeek: Decimal = 7
        static let daysPerMonth: Decimal = 30
        static let daysPerYear: Decimal = 365
        static let weeksPerMonth: Decimal = daysPerYear / monthsPerYear / daysPerWeek
        static let weeksPerYear: Decimal = daysPerYear / daysPerWeek
        static let monthsPerYear: Decimal = 12
    }

}

extension SubscriptionPeriod.Unit: CustomDebugStringConvertible {

    // swiftlint:disable missing_docs
    public var debugDescription: String {
        switch self {
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

fileprivate extension SubscriptionPeriod.Unit {

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    static func from(sk1PeriodUnit: SK1Product.PeriodUnit) -> Self? {
        switch sk1PeriodUnit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return nil
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8, *)
    static func from(sk2PeriodUnit: StoreKit.Product.SubscriptionPeriod.Unit) -> Self? {
        switch sk2PeriodUnit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return nil
        }
    }

}

// MARK: - Encodable

extension SubscriptionPeriod.Unit: Encodable { }
extension SubscriptionPeriod: Encodable { }
