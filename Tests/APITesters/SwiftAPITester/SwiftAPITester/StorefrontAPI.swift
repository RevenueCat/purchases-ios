//
//  StorefrontAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 4/13/22.
//

import RevenueCat
import StoreKit

var storefront: RevenueCat.Storefront!

func checkStorefrontAPI() {
    let identifier: String = storefront.identifier
    let countryCode: String = storefront.countryCode

    let sk1Storefront: SKStorefront? = storefront.sk1Storefront
    let sk2Storefront: StoreKit.Storefront? = storefront.sk2Storefront

    _ = Task {
        let _: RevenueCat.Storefront? = await Storefront.currentStorefront
    }

    print(identifier,
          countryCode,
          sk1Storefront!,
          sk2Storefront!)
}
