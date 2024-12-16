//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebPurchaseRedemption.swift
//
//  Created by Antonio Rico Diez on 6/11/24.

import Foundation

/// Class representing a web redemption deep link that can be redeemed by the SDK.
///
/// - Seealso: ``Purchases/redeemWebPurchase(_:)``
@objc(RCWebPurchaseRedemption) public final class WebPurchaseRedemption: NSObject {

    internal let redemptionToken: String

    internal init(redemptionToken: String) {
        self.redemptionToken = redemptionToken
    }

}
