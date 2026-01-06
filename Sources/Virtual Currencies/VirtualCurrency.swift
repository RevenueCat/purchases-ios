//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrency.swift
//
//  Created by Will Taylor on 2/27/25.

import Foundation

/// A class representing information about a virtual currency in the app.
///
/// Use this class to access information about a virtual currency, such as its current balance.
///
/// - Warning: This feature is currently in beta and is subject to change.
///
@objc(RCVirtualCurrency)
public final class VirtualCurrency: NSObject, Codable {

    /// The customer's current balance of the virtual currency.
    @objc public let balance: Int

    /// The virtual currency's name defined in the RevenueCat dashboard.
    @objc public let name: String

    /// The virtual currency's code defined in the RevenueCat dashboard.
    @objc public let code: String

    /// Virtual currency description defined in the RevenueCat dashboard.
    @objc public let serverDescription: String?

    // swiftlint:disable:next missing_docs
    @_spi(Internal) public init(
        balance: Int,
        name: String,
        code: String,
        serverDescription: String?
    ) {
        self.balance = balance
        self.name = name
        self.code = code
        self.serverDescription = serverDescription
    }
}

extension VirtualCurrency: Sendable {}

extension VirtualCurrency {
    /// Compares this virtual currency with another one.
    /// - Parameter object: The other object to compare with
    /// - Returns: `true` if both objects are virtual currencies with the same balance, `false` otherwise
    @objc public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VirtualCurrency else { return false }
        return self.balance == other.balance
        && self.name == other.name
        && self.code == other.code
        && self.serverDescription == other.serverDescription
    }
}

extension VirtualCurrency {
    internal convenience init(from response: VirtualCurrenciesResponse.VirtualCurrencyResponse) {
        self.init(
            balance: response.balance,
            name: response.name,
            code: response.code,
            serverDescription: response.description
        )
    }
}
