//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceFormatterProvider.swift
//
//  Created by Juanpe Catalán on 10/3/22.

import Foundation

/// A `NumberFormatter` provider class for prices.
/// This provider caches the formatter to improve the performance.
class PriceFormatterProvider {

    private var cachedPriceFormatterForSK1: NumberFormatter?

    func priceFormatterForSK1(with locale: Locale) -> NumberFormatter {
        func makePriceFormatterForSK1(with locale: Locale) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            return formatter
        }

        if self.cachedPriceFormatterForSK1 == nil || self.cachedPriceFormatterForSK1?.locale != locale {
            self.cachedPriceFormatterForSK1 = makePriceFormatterForSK1(with: locale)
        }

        return self.cachedPriceFormatterForSK1!
    }

    private var cachedPriceFormatterForSK2: NumberFormatter?

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func priceFormatterForSK2(withCurrencyCode currencyCode: String) -> NumberFormatter {
        func makePriceFormatterForSK2(withCurrencyCode currencyCode: String) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = .autoupdatingCurrent
            formatter.currencyCode = currencyCode
            return formatter
        }

        if self.cachedPriceFormatterForSK2 == nil || self.cachedPriceFormatterForSK2?.currencyCode != currencyCode {
            self.cachedPriceFormatterForSK2 = makePriceFormatterForSK2(withCurrencyCode: currencyCode)
        }

        return self.cachedPriceFormatterForSK2!
    }

}
