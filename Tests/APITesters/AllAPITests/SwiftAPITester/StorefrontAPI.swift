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
    let _: String = storefront.identifier
    let _: String = storefront.countryCode

    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *) {
        let _: SKStorefront? = storefront.sk1Storefront
    }

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: StoreKit.Storefront? = storefront.sk2Storefront
    }

    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *) {
        _ = Task<Void, Never> {
            let _: RevenueCat.Storefront? = await Storefront.currentStorefront
        }
    }
}
