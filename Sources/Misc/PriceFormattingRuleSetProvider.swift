//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceFormattingRuleSetProvider.swift
//
//  Created by Rick van der Linden on 26/11/2025.

// MARK: -
final class PriceFormattingRuleSetProvider: @unchecked Sendable {
    private let priceFormattingRuleSet: Atomic<PriceFormattingRuleSet?>

    init(priceFormattingRuleSet: PriceFormattingRuleSet? = nil) {
        self.priceFormattingRuleSet = Atomic(priceFormattingRuleSet)
    }

    /// Returns the currency symbol override for the given currency code, if available.
    /// - Parameter currencyCode: The ISO currency code (e.g., "RON", "USD")
    /// - Returns: The currency symbol override for the currency, or `nil` if not available
    func currencySymbolOverride(for currencyCode: String) -> PriceFormattingRuleSet.CurrencySymbolOverride? {
        return self.priceFormattingRuleSet.value?.currencySymbolOverride(currencyCode: currencyCode)
    }

    /// Updates the price formatting rule set.
    /// - Parameter ruleSet: The new rule set to use, or `nil` to clear it
    func updatePriceFormattingRuleSet(_ ruleSet: PriceFormattingRuleSet?) {
        self.priceFormattingRuleSet.value = ruleSet
    }

    static let empty = PriceFormattingRuleSetProvider(priceFormattingRuleSet: nil)
}
