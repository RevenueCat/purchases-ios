//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeepLinkHandler.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

enum DeepLinkParser {

    private static let redeemRCBPurchaseHost = "redeem_web_purchase"

    static func parse(_ url: URL) -> Purchases.DeepLink? {
        if url.host == Self.redeemRCBPurchaseHost,
           let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let redemptionToken = queryItems.first(where: { queryItem in queryItem.name == "redemption_token" })?.value {
            return Purchases.DeepLink.WebPurchaseRedemption(redemptionToken: redemptionToken)
        }
        return nil
    }

}
