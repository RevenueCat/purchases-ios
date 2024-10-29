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
@objc public class WebPurchaseRedemptionResult: NSObject {

    private override init() {}

    /// Represents that the web purchase was redeemed successfully
    public final class Success: WebPurchaseRedemptionResult {

        /// ``CustomerInfo`` after the successful redemption.
        public let customerInfo: CustomerInfo

        internal init(customerInfo: CustomerInfo) {
            self.customerInfo = customerInfo
        }

    }

    /// Represents that the web purchase failed to redeem
    public final class Error: WebPurchaseRedemptionResult {

        /// Error causing the redemption to fail
        public let error: PublicError

        internal init(error: PublicError) {
            self.error = error
        }

    }

}
