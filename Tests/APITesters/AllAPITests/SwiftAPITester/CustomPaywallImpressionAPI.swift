//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallImpressionAPI.swift
//

import Foundation
@_spi(Experimental) import RevenueCat

func checkCustomPaywallImpressionAPI() {
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
        let purchases = Purchases.shared

        // CustomPaywallImpressionParams API
        let paramsDefault: CustomPaywallImpressionParams = CustomPaywallImpressionParams()
        let paramsWithId: CustomPaywallImpressionParams = CustomPaywallImpressionParams(paywallId: "my-paywall")
        let paramsWithNil: CustomPaywallImpressionParams = CustomPaywallImpressionParams(paywallId: nil)

        // CustomPaywallImpressionParams properties
        let paywallId: String? = paramsWithId.paywallId

        // trackCustomPaywallImpression API
        purchases.trackCustomPaywallImpression(paramsDefault)
        purchases.trackCustomPaywallImpression(paramsWithId)
        purchases.trackCustomPaywallImpression()
    }
}
