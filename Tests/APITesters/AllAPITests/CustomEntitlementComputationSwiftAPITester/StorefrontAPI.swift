//
//  StorefrontAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 4/13/22.
//

import RevenueCat_CustomEntitlementComputation
import StoreKit

var storefront: RevenueCat_CustomEntitlementComputation.Storefront!

func checkStorefrontAPI() {
    let identifier: String = storefront.identifier
    let countryCode: String = storefront.countryCode

    let sk1Storefront: SKStorefront? = storefront.sk1Storefront
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2Storefront: StoreKit.Storefront? = storefront.sk2Storefront
        print(sk2Storefront!)
    }

    _ = Task<Void, Never> {
        let _: RevenueCat_CustomEntitlementComputation.Storefront? = await Storefront.currentStorefront
    }

    print(identifier,
          countryCode,
          sk1Storefront!)
}
