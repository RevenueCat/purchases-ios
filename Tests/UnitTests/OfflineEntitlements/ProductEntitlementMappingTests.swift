//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMappingTests.swift
//
//  Created by Nacho Soto on 3/22/23.

import Nimble
import XCTest

@testable import RevenueCat

class ProductEntitlementMappingTests: TestCase {

    func testResponseToMapping() {
        let response = ProductEntitlementMappingResponse(products: [
            .init(identifier: "product_1", entitlements: ["pro_1"]),
            .init(identifier: "product_2", entitlements: ["pro_1", "pro_2"]),
            .init(identifier: "product_3", entitlements: ["pro_4"])
        ])
        let mapping = response.toMapping()

        expect(mapping.entitlementsByProduct) == [
            "product_1": [
                "pro_1"
            ],
            "product_2": [
                "pro_1",
                "pro_2"
            ],
            "product_3": [
                "pro_4"
            ]
        ]
    }

    func testResponseToMappingWithDuplicateProductIdentifiers() {
        let response = ProductEntitlementMappingResponse(products: [
            .init(identifier: "product_1", entitlements: ["pro_1"]),
            .init(identifier: "product_1", entitlements: ["pro_1", "pro_2", "pro_3"]),
            .init(identifier: "product_2", entitlements: ["pro_4"])
        ])
        let mapping = response.toMapping()

        expect(mapping.entitlementsByProduct) == [
            "product_1": [
                "pro_1",
                "pro_2",
                "pro_3"
            ],
            "product_2": [
                "pro_4"
            ]
        ]
    }

    func testEncoding() throws {
        let response = ProductEntitlementMapping(entitlementsByProduct: [
            "product_1": [
                "pro_1"
            ],
            "product_2": [
                "pro_1",
                "pro_2"
            ],
            "product_3": [
                "pro_4"
            ]
        ])

        expect(try response.encodeAndDecode()) == response
    }

}
