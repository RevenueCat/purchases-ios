//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMappingResponse.swift
//
//  Created by Nacho Soto on 3/17/23.

import Foundation

/// Response from product entitlement mapping endpoint
/// - Seealso: `ProductEntitlementMapping`
struct ProductEntitlementMappingResponse {

    var productEntitlementMapping: [String: Product]

    private enum CodingKeys: String, CodingKey {
        case productEntitlementMapping = "product_entitlement_mapping"
    }

}

extension ProductEntitlementMappingResponse {

    struct Product {

        var identifier: String
        var entitlements: [String]

    }

}

// MARK: - Codable
extension ProductEntitlementMappingResponse.Product: Codable {

    private enum CodingKeys: String, CodingKey {

        case identifier = "product_identifier"
        case entitlements

    }

}

extension ProductEntitlementMappingResponse: Codable {}
extension ProductEntitlementMappingResponse: HTTPResponseBody {}
