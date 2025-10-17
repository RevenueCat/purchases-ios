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
public final class PriceFormatterProvider: Sendable {
    
    private let priceFormattingRuleSet: PriceFormattingRuleSet?
    
    init(priceFormattingRuleSet: PriceFormattingRuleSet? = nil) {
        self.priceFormattingRuleSet = priceFormattingRuleSet
    }

    private let cachedPriceFormatterForSK1: Atomic<NumberFormatter?> = nil

    func priceFormatterForSK1(with locale: Locale) -> NumberFormatter {
        func makePriceFormatterForSK1(
            with locale: Locale,
            currencySymbolOverride: PriceFormattingRuleSet.CurrencySymbolOverride?
        ) -> NumberFormatter {
            let formatter: NumberFormatter
            if let currencySymbolOverride {
                formatter = CurrencySymbolOverridingPriceFormatter(
                    currencySymbolOverride: currencySymbolOverride
                )
            } else {
                formatter = NumberFormatter()
            }
            formatter.numberStyle = .currency
            formatter.locale = locale
            return formatter
        }

        return self.cachedPriceFormatterForSK1.modify { formatter in
            if let formatter = formatter as? CurrencySymbolOverridingPriceFormatter {
                if formatter.locale == locale,
                    formatter.currencySymbolOverride == priceFormattingRuleSet?.currencySymbolOverride(currencyCode: formatter.currencyCode) {
                    return formatter
                }
            }
            else if let formatter = formatter, formatter.locale == locale {
                return formatter
            }
            
            var newFormatter =  makePriceFormatterForSK1(
                with: locale,
                currencySymbolOverride: nil
            )
            
            // If there is a currency symbol override for the currencyCode of the new formatter, use that
            if let currencySymbolOverride = priceFormattingRuleSet?.currencySymbolOverride(currencyCode: newFormatter.currencyCode) {
                newFormatter =  makePriceFormatterForSK1(
                    with: locale,
                    currencySymbolOverride: currencySymbolOverride
                )
            }
            
            formatter = newFormatter

            return newFormatter
        }
    }

    private let cachedPriceFormatterForSK2: Atomic<NumberFormatter?> = nil

    func priceFormatterForSK2(
        withCurrencyCode currencyCode: String,
        locale: Locale = .autoupdatingCurrent
    ) -> NumberFormatter {
        return self.cachedPriceFormatterForSK2.modify { formatter in
            let newFormatter = createPriceFormatterIfNeeded(
                cachedPriceFormatter: formatter,
                currencyCode: currencyCode,
                locale: locale
            )
            if newFormatter != formatter {
                formatter = newFormatter
            }
            return newFormatter
        }
    }

    private let cachedPriceFormatterForWebProducts: Atomic<NumberFormatter?> = nil

    func priceFormatterForWebProducts(
        withCurrencyCode currencyCode: String,
        locale: Locale = .autoupdatingCurrent
    ) -> NumberFormatter {
        return self.cachedPriceFormatterForWebProducts.modify { formatter in
            let newFormatter = createPriceFormatterIfNeeded(
                cachedPriceFormatter: formatter,
                currencyCode: currencyCode,
                locale: locale
            )
            if newFormatter != formatter {
                formatter = newFormatter
            }
            return newFormatter
        }
    }
    
    private func createPriceFormatterIfNeeded(
        cachedPriceFormatter: NumberFormatter?,
        currencyCode: String,
        locale: Locale
    ) -> NumberFormatter {
        let currencySymbolOverride = priceFormattingRuleSet?.currencySymbolOverride(
            currencyCode: currencyCode
        )
        
        if let formatter = cachedPriceFormatter as? CurrencySymbolOverridingPriceFormatter {
            if formatter.currencyCode == currencyCode, formatter.locale == locale, formatter.currencySymbolOverride == currencySymbolOverride {
                return formatter
            }
        }
        else if let formatter = cachedPriceFormatter, formatter.currencyCode == currencyCode, formatter.locale == locale {
            return formatter
        }
        
        return makePriceFormatter(
            with: currencyCode,
            locale: locale,
            currencySymbolOverride: currencySymbolOverride
        )
    }
    
    private func makePriceFormatter(
        with currencyCode: String,
        locale: Locale,
        currencySymbolOverride: PriceFormattingRuleSet.CurrencySymbolOverride?
    ) -> NumberFormatter {
        let formatter: NumberFormatter
        if let currencySymbolOverride {
            formatter = CurrencySymbolOverridingPriceFormatter(
                currencySymbolOverride: currencySymbolOverride
            )
        } else {
            formatter = NumberFormatter()
        }
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter
    }
}

class CurrencySymbolOverridingPriceFormatter: NumberFormatter, @unchecked Sendable {
    
    let currencySymbolOverride: PriceFormattingRuleSet.CurrencySymbolOverride
    private var numberFormatterCache = [PriceFormattingRuleSet.CurrencySymbolOverride.PluralRule: NumberFormatter]()
    
    init(currencySymbolOverride: PriceFormattingRuleSet.CurrencySymbolOverride) {
        self.currencySymbolOverride = currencySymbolOverride
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func string(from number: NSNumber) -> String? {
        formatter(for: rule(for: number)).string(from: number)
    }
    
    /// Cardinal plural selection per CLDR/ICU baseline:
    /// - Non-integers → .other
    /// - Integers: 0 → .zero, 1 → .one, 2 → .two, else → .other
    /// This function is intentionally locale-agnostic; apply your locale-specific rules upstream.
    /// Spec reference: Unicode TR35 (Plural Rules).
    private func rule(for value: NSNumber) -> PriceFormattingRuleSet.CurrencySymbolOverride.PluralRule {
        let n = value.doubleValue

        // Guard weird numerics
        if n.isNaN || n.isInfinite { return .other }
        
        guard let intValue = Int64(exactly: n) else {
            return .other
        }
        
        // Check if value has any fractional part
        let isInteger = n == Double(intValue)

        // Per CLDR/ICU, decimals are "other" unless a locale defines explicit fraction rules.
        guard isInteger else { return .other }

        // Integer-only mapping; locale-specific categories like "few"/"many" are handled elsewhere.
        switch intValue {
        case 0: return .zero
        case 1: return .one
        case 2: return .two
        default: return .other
        }
    }
    
    private func formatter(for rule: PriceFormattingRuleSet.CurrencySymbolOverride.PluralRule) -> NumberFormatter {
        if let formatter = numberFormatterCache[rule] {
            return formatter
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = numberStyle
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbolOverride.value(for: rule)
        numberFormatterCache[rule] = formatter
        return formatter
    }
}
