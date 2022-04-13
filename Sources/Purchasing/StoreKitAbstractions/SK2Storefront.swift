//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2Storefront.swift
//
//  Created by Nacho Soto on 4/13/22.

import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2Storefront: StorefrontType {

    init(_ sk2Storefront: StoreKit.Storefront) {
        self.underlyingSK2Storefront = sk2Storefront

        self.identifier = sk2Storefront.id
        self.countryCode = sk2Storefront.countryCode
    }

    let underlyingSK2Storefront: StoreKit.Storefront

    let identifier: String
    let countryCode: String

}
