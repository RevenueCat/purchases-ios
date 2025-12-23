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
@objc(RCVirtualCurrencies) public final class VirtualCurrencies: NSObject, Codable {

    /// Dictionary of all ``VirtualCurrency`` objects keyed by virtual currency code.
    /// This dictionary can also be accessed through an index subscript on ``VirtualCurrencies``, e.g.
    /// `virtualCurrencies["VC_CODE"]`.
    @objc public let all: [String: VirtualCurrency]

    // swiftlint:disable:next missing_docs
    @_spi(Internal) public init(virtualCurrencies: [String: VirtualCurrency]) {
        self.all = virtualCurrencies
    }

    /// #### Related Symbols
    /// - ``all``
    @objc public subscript(key: String) -> VirtualCurrency? {
        return self.all[key]
    }
}

extension VirtualCurrencies: Sendable {}

extension VirtualCurrencies {
    /// Compares two ``VirtualCurrencies`` objects for equality by comparing their underlying dictionaries.
    /// - Parameter object: The object to compare against
    /// - Returns: `true` if the objects are equal, `false` otherwise
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VirtualCurrencies else { return false }
        return self.all == other.all
    }
}

extension VirtualCurrencies {
    internal convenience init(from response: VirtualCurrenciesResponse) {
        let convertedVCMap = response.virtualCurrencies.mapValues({ virtualCurrencyResponse in
            return VirtualCurrency(from: virtualCurrencyResponse)
        })

        self.init(virtualCurrencies: convertedVCMap)
    }
}
