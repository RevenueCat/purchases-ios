//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyInfos.swift
//
//  Created by Will Taylor on 5/21/25.

import Foundation

/// This class contains all the virtual currencies associated to the user.
@objc(RCVirtualCurrencyInfos) public final class VirtualCurrencyInfos: NSObject {

    /// Dictionary of all VirtualCurrencyInfo(``VirtualCurrencyInfo``) objects keyed by virtual currency code.
    /// This dictionary can also be access through an index subscript on ``VirtualCurrencyInfos``, e.g.
    /// `virtualCurrencyInfos["VC_CODE"]`.
    @objc public let all: [String: VirtualCurrencyInfo]

    internal init(virtualCurrencies: [String : VirtualCurrencyInfo]) {
        self.all = virtualCurrencies
    }

    /// #### Related Symbols
    /// - ``all``
    @objc public subscript(key: String) -> VirtualCurrencyInfo? {
        return self.all[key]
    }
}

public extension VirtualCurrencyInfos {
    /// Returns a dictionary containing only the virtual currencies that have a balance greater than zero.
    /// - Returns: A dictionary of virtual currency codes to their corresponding info objects,
    ///     filtered to only include those with non-zero balances.
    var virtualCurrenciesWithNonZeroBalance: [String: VirtualCurrencyInfo] {
        return Dictionary(uniqueKeysWithValues: self.all.filter { $1.balance > 0 })
    }

    /// Returns a dictionary containing only the virtual currencies that have a balance of zero.
    /// - Returns: A dictionary of virtual currency codes to their corresponding info objects,
    ///     filtered to only include those with zero balances.
    var virtualCurrenciesWithZeroBalance: [String: VirtualCurrencyInfo] {
        return Dictionary(uniqueKeysWithValues: self.all.filter { $1.balance == 0 })
    }
}
