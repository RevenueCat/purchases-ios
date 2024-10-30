//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebPurchaseRedemptionResult.swift
//
//  Created by Antonio Rico Diez on 29/10/24.

import Foundation

/// Represents the result of a web purchase redemption
/// - Seealso: ``Purchases/redeemWebPurchase(_:)``
public enum WebPurchaseRedemptionResult: Sendable {

    /// Represents that the web purchase was redeemed successfully
    case success(_ customerInfo: CustomerInfo)
    /// Represents that the web purchase failed to redeem
    case error(_ error: PublicError)

}
