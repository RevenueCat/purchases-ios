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

    private lazy var cachedPriceFormatterForSK1: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    func priceFormatterForSK1(withLocale locale: Locale) -> NumberFormatter {
        if cachedPriceFormatterForSK1.locale != locale {
            cachedPriceFormatterForSK1.locale = locale
        }
        return cachedPriceFormatterForSK1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private lazy var cachedPriceFormatterForSK2: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func priceFormatterForSK2(withCurrencyCode currencyCode: String) -> NumberFormatter {
        if cachedPriceFormatterForSK2.currencyCode != currencyCode {
            cachedPriceFormatterForSK2.currencyCode = currencyCode
        }
        return cachedPriceFormatterForSK2
    }

}
