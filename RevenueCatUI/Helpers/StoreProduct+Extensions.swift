//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProduct+Extensions.swift
//
//  Created by Cesar de la Vega on 25/9/24.

import Foundation
import RevenueCat

extension StoreProduct {

    /// Keeps display rounding out of relative discount calculations.
    var pricePerMonthForDiscount: MonthlyPrice? {
        guard let period = self.subscriptionPeriod,
              period.value > 0 else {
            return nil
        }

        let value = Decimal(period.value)
        let year = SubscriptionPeriod(value: 1, unit: .year)
        switch period.unit {
        case .day:
            let month = SubscriptionPeriod(value: 1, unit: .month)
            return .init(numerator: self.price * month.numberOfUnitsAs(unit: .day), denominator: value)
        case .week:
            let week = SubscriptionPeriod(value: 1, unit: .week)
            return .init(
                numerator: self.price * year.numberOfUnitsAs(unit: .day),
                denominator: value * year.numberOfUnitsAs(unit: .month) * week.numberOfUnitsAs(unit: .day)
            )
        case .month:
            return .init(numerator: self.price, denominator: value)
        case .year:
            return .init(numerator: self.price, denominator: value * year.numberOfUnitsAs(unit: .month))
        }
    }

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        guard let period = self.subscriptionPeriod else {
            return self.localizedPriceString
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }

}

extension StoreProduct {

    /// Retains conversion factors until the ratio is calculated, including repeating weekly rates.
    struct MonthlyPrice {

        let numerator: Decimal
        let denominator: Decimal

        func discount(relativeTo mostExpensive: Self?) -> Decimal? {
            guard let mostExpensive, self < mostExpensive else {
                return nil
            }

            let fullPrice = mostExpensive.numerator * self.denominator
            let discountedPrice = self.numerator * mostExpensive.denominator
            return (fullPrice - discountedPrice) / fullPrice
        }

    }

}

extension StoreProduct.MonthlyPrice: Comparable {

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.numerator * rhs.denominator == rhs.numerator * lhs.denominator
    }

}
