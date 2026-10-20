//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiscountSavings.swift

import Foundation
@_spi(Internal) import RevenueCat

/// Savings against a baseline over the first billing period or the full offer term.
///
/// The Android and web implementations must produce the same numbers.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DiscountSavings: Equatable {

    /// Rounded half up to the currency's minor unit.
    let amount: Decimal
    /// Computed before rounding `amount`.
    let relative: Double

    /// An offer counts for the part of the first period it covers; the regular price is prorated over the rest.
    ///
    /// `nil` when the product isn't a subscription, the baseline is unknown, or nothing is saved.
    init?(firstPeriodOf product: StoreProduct, discount: StoreProductDiscount?, baseline: Decimal?) {
        guard let baseline, let period = product.subscriptionPeriod else {
            return nil
        }

        let cost = discount.map {
            Self.firstPeriodCost(price: product.price, period: period, discount: $0)
        } ?? product.price

        self.init(product: product, baseline: baseline, cost: cost)
    }

    /// Without a paid offer, the term is one period of the product at its regular price. A free trial counts as
    /// no offer, since "100% off" isn't the claim this makes.
    ///
    /// `nil` when the product isn't a subscription, the most expensive price is unknown, or nothing is saved.
    init?(offerTermOf product: StoreProduct, discount: StoreProductDiscount?, mostExpensivePricePerMonth: Decimal?) {
        guard let mostExpensivePricePerMonth, let period = product.subscriptionPeriod else {
            return nil
        }

        let months: Decimal
        let cost: Decimal
        if let discount, discount.price > 0 {
            months = discount.subscriptionPeriod.numberOfUnitsAs(unit: .month) * Decimal(discount.numberOfPeriods)
            cost = Self.offerCost(discount)
        } else {
            months = period.numberOfUnitsAs(unit: .month)
            cost = product.price
        }

        self.init(product: product, baseline: mostExpensivePricePerMonth * months, cost: cost)
    }

    private init?(product: StoreProduct, baseline: Decimal, cost: Decimal) {
        let saved = baseline - cost
        let amount = saved.rounded(scale: product.priceFormatter?.maximumFractionDigits ?? 2)
        guard baseline > 0, amount > 0 else {
            return nil
        }

        self.amount = amount
        self.relative = (saved / baseline as NSDecimalNumber).doubleValue
    }

    static func firstPeriodCost(
        price: Decimal,
        period: SubscriptionPeriod,
        discount: StoreProductDiscount
    ) -> Decimal {
        let windowDays = period.numberOfUnitsAs(unit: .day)
        let offerDays = discount.subscriptionPeriod.numberOfUnitsAs(unit: .day) * Decimal(discount.numberOfPeriods)
        guard windowDays > 0, offerDays > 0 else {
            return price
        }

        let coveredDays = min(offerDays, windowDays)
        return Self.offerCost(discount) * coveredDays / offerDays + price * (windowDays - coveredDays) / windowDays
    }

    /// A free trial or pay-up-front offer is a single period spanning the whole offer.
    private static func offerCost(_ discount: StoreProductDiscount) -> Decimal {
        switch discount.paymentMode {
        case .freeTrial:
            return 0
        case .payUpFront:
            return discount.price
        case .payAsYouGo:
            return discount.price * Decimal(discount.numberOfPeriods)
        }
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
