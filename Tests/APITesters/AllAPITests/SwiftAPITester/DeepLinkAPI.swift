//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeepLinkAPI.swift
//
//  Created by Toni Rico on 10/30/24.

import Foundation
import RevenueCat

var deepLink: Purchases.DeepLink!
func checkDeepLinkAPI() {
    let webPurchaseRedemption: Purchases.DeepLink.WebPurchaseRedemption? = deepLink as? Purchases.DeepLink.WebPurchaseRedemption

    print(webPurchaseRedemption!)
}

func checkParseAsDeepLink(_ url: URL) {
    let deepLink: Purchases.DeepLink? = Purchases.parseAsDeepLink(url)

    print(deepLink!)
}
