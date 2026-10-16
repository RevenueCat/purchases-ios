//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FirstPeriodSavings.swift

import Foundation
@_spi(Internal) import RevenueCat

/// What a subscriber saves over the product's first billing period: a yearly product is measured over its first
/// year, a monthly one over its first month.
///
/// An offer counts for the part of that period it covers, and the regular price is prorated over the rest.
/// The Android implementation must produce the same numbers.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FirstPeriodSavings: Equatable {

    enum Baseline {

        /// The product's own price for one period.
        case standardPrice
        /// The most expensive per-month price in the tab, scaled to the product's period.
        case mostExpensive(pricePerMonth: Double?)

    }

    /// Rounded half up to the currency's minor unit.
    let amount: Decimal
    let baseline: Decimal

    var relative: Double {
        return (self.amount / self.baseline as NSDecimalNumber).doubleValue
    }

    /// `nil` when the product isn't a subscription, the baseline is unknown, or nothing is saved.
    init?(product: StoreProduct, discount: StoreProductDiscount?, baseline: Baseline) {
        guard let period = product.subscriptionPeriod else {
            return nil
        }

        let baselineAmount: Decimal
        switch baseline {
        case .standardPrice:
            baselineAmount = product.price
        case let .mostExpensive(pricePerMonth):
            guard let pricePerMonth else {
                return nil
            }
            baselineAmount = Decimal(pricePerMonth) * period.numberOfUnitsAs(unit: .month)
        }

        let cost = discount.map {
            Self.firstPeriodCost(price: product.price, period: period, discount: $0)
        } ?? product.price

        let amount = (baselineAmount - cost).rounded(scale: product.priceFormatter?.maximumFractionDigits ?? 2)
        guard baselineAmount > 0, amount > 0 else {
            return nil
        }

        self.amount = amount
        self.baseline = baselineAmount
    }

    static func firstPeriodCost(
        price: Decimal,
        period: SubscriptionPeriod,
        discount: StoreProductDiscount
    ) -> Decimal {
        let windowDays = period.numberOfUnitsAs(unit: .day)
        // A free trial or pay-up-front offer is a single period spanning the whole offer.
        let offerDays = discount.subscriptionPeriod.numberOfUnitsAs(unit: .day) * Decimal(discount.numberOfPeriods)
        guard windowDays > 0, offerDays > 0 else {
            return price
        }

        let offerCost: Decimal
        switch discount.paymentMode {
        case .freeTrial:
            offerCost = 0
        case .payUpFront:
            offerCost = discount.price
        case .payAsYouGo:
            offerCost = discount.price * Decimal(discount.numberOfPeriods)
        }

        let coveredDays = min(offerDays, windowDays)
        return offerCost * coveredDays / offerDays + price * (windowDays - coveredDays) / windowDays
    }

}

private extension Decimal {

    func rounded(scale: Int) -> Decimal {
        var value = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, scale, .plain)
        return rounded
    }

}
