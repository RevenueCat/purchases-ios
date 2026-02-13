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

    func priceStringWithZeroDecimalFormatting(
        _ priceString: String,
        showZeroDecimalPlacePrices: Bool
    ) -> String {
        guard showZeroDecimalPlacePrices else {
            return priceString
        }

        guard let price = self.number(from: priceString)?.doubleValue else {
            return priceString
        }

        let roundedPrice = round(price * 100) / 100.0
        guard roundedPrice.truncatingRemainder(dividingBy: 1) == 0 else {
            return priceString
        }

        guard let copy = self.copy() as? NumberFormatter else {
            return priceString
        }
        copy.maximumFractionDigits = 0
        return copy.string(from: NSNumber(value: price)) ?? priceString
    }

}
