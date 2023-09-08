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
final class PriceFormatterProvider: Sendable {

    private let cachedPriceFormatterForSK1: Atomic<NumberFormatter?> = nil

    func priceFormatterForSK1(with locale: Locale) -> NumberFormatter {
        func makePriceFormatterForSK1(with locale: Locale) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            return formatter
        }

        return self.cachedPriceFormatterForSK1.modify { formatter in
            guard let formatter = formatter, formatter.locale == locale else {
                let newFormatter =  makePriceFormatterForSK1(with: locale)
                formatter = newFormatter

                return newFormatter
            }

            return formatter
        }
    }

    private let cachedPriceFormatterForSK2: Atomic<NumberFormatter?> = nil

    func priceFormatterForSK2(
        withCurrencyCode currencyCode: String,
        locale: Locale = .autoupdatingCurrent
    ) -> NumberFormatter {
        func makePriceFormatterForSK2(with currencyCode: String) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            formatter.currencyCode = currencyCode
            return formatter
        }

        return self.cachedPriceFormatterForSK2.modify { formatter in
            guard let formatter = formatter, formatter.currencyCode == currencyCode, formatter.locale == locale else {
                let newFormatter = makePriceFormatterForSK2(with: currencyCode)
                formatter = newFormatter

                return newFormatter
            }

            return formatter
        }
    }

}
