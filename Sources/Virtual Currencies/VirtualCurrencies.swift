//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencies.swift
//
//  Created by Will Taylor on 5/21/25.

import Foundation

/// This class contains all the virtual currencies associated to the user.
@objc(RCVirtualCurrencies) public final class VirtualCurrencies: NSObject {

    /// Dictionary of all VirtualCurrency(``VirtualCurrency``) objects keyed by virtual currency code.
    /// This dictionary can also be access through an index subscript on ``VirtualCurrencies``, e.g.
    /// `virtualCurrencies["VC_CODE"]`.
    @objc public let all: [String: VirtualCurrency]

    internal init(virtualCurrencies: [String: VirtualCurrency]) {
        self.all = virtualCurrencies
    }

    /// #### Related Symbols
    /// - ``all``
    @objc public subscript(key: String) -> VirtualCurrency? {
        return self.all[key]
    }
}

public extension VirtualCurrencies {
    /// Returns a dictionary containing only the virtual currencies that have a balance greater than zero.
    /// - Returns: A dictionary of virtual currency codes to their corresponding info objects,
    ///     filtered to only include those with non-zero balances.
    var virtualCurrenciesWithNonZeroBalance: [String: VirtualCurrency] {
        return Dictionary(uniqueKeysWithValues: self.all.filter { $1.balance > 0 })
    }

    /// Returns a dictionary containing only the virtual currencies that have a balance of zero.
    /// - Returns: A dictionary of virtual currency codes to their corresponding info objects,
    ///     filtered to only include those with zero balances.
    var virtualCurrenciesWithZeroBalance: [String: VirtualCurrency] {
        return Dictionary(uniqueKeysWithValues: self.all.filter { $1.balance == 0 })
    }
}

extension VirtualCurrencies: Sendable {}
extension VirtualCurrencies: Codable {}
