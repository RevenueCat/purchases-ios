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
public final class VirtualCurrency: NSObject {

    /// The customer's current balance of the virtual currency.
    @objc public let balance: Int

    internal init(balance: Int) {
        self.balance = balance
    }
}

extension VirtualCurrency: Codable {}
extension VirtualCurrency: Sendable {}
