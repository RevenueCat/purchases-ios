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

    func priceFormatterForSK1(withLocale locale: Locale) -> NumberFormatter {

        func makePriceFormatterForSK1() -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter
        }

        if cachedPriceFormatterForSK1 == nil {
            cachedPriceFormatterForSK1 = makePriceFormatterForSK1()
        }

        if cachedPriceFormatterForSK1?.locale != locale {
            // If the currency code is different, we store and return a copy, so as not to modify
            // the previously returned formatters.
            cachedPriceFormatterForSK1 = cachedPriceFormatterForSK1?.copy() as? NumberFormatter
            cachedPriceFormatterForSK1?.locale = locale
        }

        return cachedPriceFormatterForSK1!
    }

    private var cachedPriceFormatterForSK2: NumberFormatter?

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func priceFormatterForSK2(withCurrencyCode currencyCode: String) -> NumberFormatter {

        func makePriceFormatterForSK2() -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = .autoupdatingCurrent
            return formatter
        }

        if cachedPriceFormatterForSK2 == nil {
            cachedPriceFormatterForSK2 = makePriceFormatterForSK2()
        }

        if cachedPriceFormatterForSK2?.currencyCode != currencyCode {
            // If the currency code is different, we store and return a copy, so as not to modify
            // the previously returned formatters.
            cachedPriceFormatterForSK2 = cachedPriceFormatterForSK2?.copy() as? NumberFormatter
            cachedPriceFormatterForSK2?.currencyCode = currencyCode
        }

        return cachedPriceFormatterForSK2!
    }

}
