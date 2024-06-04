//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1Storefront.swift
//
//  Created by Nacho Soto on 4/13/22.

import StoreKit

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, macCatalyst 13.1, *)
internal struct SK1Storefront: StorefrontType {

    init(_ sk1Storefront: SKStorefront) {
        self.underlyingSK1Storefront = sk1Storefront

        self.identifier = sk1Storefront.identifier
        self.countryCode = sk1Storefront.countryCode
    }

    let underlyingSK1Storefront: SKStorefront

    let identifier: String
    let countryCode: String

}
