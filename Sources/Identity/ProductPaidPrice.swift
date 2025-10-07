//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductPaidPrice.swift
//
//  Created by Facundo Menzella on 15/1/25.

import Foundation

/// Price paid for the product
@objc(RCProductPaidPrice) public final class ProductPaidPrice: NSObject, Sendable {

    /// Currency paid
    @objc public let currency: String

    /// Amount paid
    @objc public let amount: Double

    /// Formatted price of the item, including its currency sign. For example $3.00.
    @objc public let formatted: String

    private static let formatterCache = NSCache<NSString, NumberFormatter>()

    /// ProductPaidPrice initializer (maintains backward compatibility)
    /// - Parameters:
    ///   - currency: Currency paid
    ///   - amount: Amount paid
    public convenience init(currency: String, amount: Double) {
        self.init(currency: currency, amount: amount, locale: .current)
    }

    /// ProductPaidPrice initialiser
    /// - Parameters:
    ///   - currency: Currency paid
    ///   - amount: Amount paid
    ///   - formatted: Formatted price string with currency symbol
    init(currency: String, amount: Double, formatted: String) {
        self.currency = currency
        self.amount = amount
        self.formatted = formatted
    }

    /// Convenience initializer that formats the price using the provided locale
    /// - Parameters:
    ///   - currency: Currency code (e.g., "USD", "EUR")
    ///   - amount: Amount as a decimal value
    ///   - locale: Locale for formatting (defaults to current locale)
    public convenience init(currency: String, amount: Double, locale: Locale = .current) {
        let formatted = Self.formatPrice(currency: currency, amount: amount, locale: locale)
        self.init(currency: currency, amount: amount, formatted: formatted)
    }

    /// Formats a price with currency using NumberFormatter
    /// - Parameters:
    ///   - currency: The currency code
    ///   - amount: The price amount
    ///   - locale: The locale for formatting
    /// - Returns: Formatted price string (e.g., "$3.00", "€7.99")
    static func formatPrice(currency: String, amount: Double, locale: Locale = .current) -> String {
        let cacheKey = "\(locale.identifier)-\(currency)" as NSString

        let formatter: NumberFormatter
        if let cachedFormatter = formatterCache.object(forKey: cacheKey) {
            formatter = cachedFormatter
        } else {
            formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            formatter.currencyCode = currency
            formatterCache.setObject(formatter, forKey: cacheKey)
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
