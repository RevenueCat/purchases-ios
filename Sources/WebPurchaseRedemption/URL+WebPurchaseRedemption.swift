//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URL+WebPurchaseRedemption.swift
//
//  Created by Antonio Rico Diez on 8/11/24.

import Foundation

extension URL {

    /// Parses a URL and converts it to a ``WebPurchaseRedemption`` if possible that can be
    /// redeemed using ``Purchases/redeemWebPurchase(_:)`
    ///
    /// - Seealso: ``Purchases/redeemWebPurchase(_:)``
    public var asWebPurchaseRedemption: WebPurchaseRedemption? {
        return Purchases.parseAsWebPurchaseRedemption(self)
    }

}
