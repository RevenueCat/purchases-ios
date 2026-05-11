//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceFormatterExtensions.swift

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension NumberFormatter {

    /// If `showZeroDecimalPlacePrices` is `true` and the given price is a whole number,
    /// returns the price formatted without decimal places (e.g. "$2.00" → "$2").
    /// Otherwise, formats the price normally.
    func formattedPriceStrippingTrailingZerosIfNeeded(
        _ price: Decimal,
        showZeroDecimalPlacePrices: Bool
    ) -> String? {
        guard showZeroDecimalPlacePrices, price.isWholeNumber else {
            return self.string(from: price as NSDecimalNumber)
        }

        guard let copy = self.copy() as? NumberFormatter else {
            return self.string(from: price as NSDecimalNumber)
        }
        copy.maximumFractionDigits = 0
        return copy.string(from: price as NSDecimalNumber)
    }

    /// Convenience overload that parses the price from an already-formatted string.
    func formattedPriceStrippingTrailingZerosIfNeeded(
        from priceString: String,
        showZeroDecimalPlacePrices: Bool
    ) -> String {
        guard showZeroDecimalPlacePrices else {
            return priceString
        }

        guard let number = self.number(from: priceString) else {
            return priceString
        }

        return self.formattedPriceStrippingTrailingZerosIfNeeded(
            number.decimalValue,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        ) ?? priceString
    }

}

private extension Decimal {

    var isWholeNumber: Bool {
        var value = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return self == rounded
    }

}
