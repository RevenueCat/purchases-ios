//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebOfferingProductsResponse.swift
//
//  Created by Toni Rico on 5/6/25.

import Foundation

struct WebOfferingProductsResponse {

    struct Package {
        let identifier: String
        let webCheckoutUrl: String
        let productDetails: WebBillingProductsResponse.Product
    }

    struct Offering {
        let identifier: String
        let description: String?
        let packages: [String: Package]
    }

    let offerings: [String: Offering]

}

extension WebOfferingProductsResponse.Offering: Codable, Equatable {}
extension WebOfferingProductsResponse.Package: Codable, Equatable {}

extension WebOfferingProductsResponse: Codable, Equatable {}

extension WebOfferingProductsResponse: HTTPResponseBody {}
