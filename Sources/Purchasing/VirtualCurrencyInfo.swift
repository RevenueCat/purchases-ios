//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyInfo.swift
//
//  Created by Will Taylor on 2/27/25.

#if ENABLE_VIRTUAL_CURRENCIES
import Foundation

/// A class representing information about a virtual currency in the app.
///
/// Use this class to access information about a virtual currency, such as its current balance.
///
/// - Warning: This feature is currently in beta and is subject to change.
///
@objc(RCVirtualCurrencyInfo)
public final class VirtualCurrencyInfo: NSObject {

    /// The current balance of the virtual currency.
    ///
    /// This property represents the amount of virtual currency currently available.
    /// The balance is represented as an integer value.
    @objc public let balance: Int64

    init(with virtualCurrencyInfo: CustomerInfoResponse.VirtualCurrencyInfo) {
        self.balance = virtualCurrencyInfo.balance
    }
}

extension VirtualCurrencyInfo: Codable {}
extension VirtualCurrencyInfo: Sendable {}

#endif
