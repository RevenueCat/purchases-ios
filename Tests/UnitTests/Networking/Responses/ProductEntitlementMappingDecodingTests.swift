//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductEntitlementMappingDecodingTests.swift
//
//  Created by Nacho Soto on 3/17/23.

import Nimble
@testable import RevenueCat
import XCTest

class ProductEntitlementMappingDecodingTests: BaseHTTPResponseTest {

    private var response: ProductEntitlementMappingResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try Self.decodeFixture("ProductsEntitlements")
    }

    func testDataIsCorrect() {
        let products = self.response.products

        expect(products).to(haveCount(3))

        expect(products["com.revenuecat.foo_1"]?.identifier) == "com.revenuecat.foo_1"
        expect(products["com.revenuecat.foo_1"]?.entitlements) == ["pro_1"]

        expect(products["com.revenuecat.foo_2"]?.identifier) == "com.revenuecat.foo_2"
        expect(products["com.revenuecat.foo_2"]?.entitlements) == ["pro_1", "pro_2"]

        expect(products["com.revenuecat.foo_3"]?.identifier) == "com.revenuecat.foo_3"
        expect(products["com.revenuecat.foo_3"]?.entitlements) == ["pro_2"]
    }

    func testDecodesBasePlanId() throws {
        let data = try XCTUnwrap("""
        {
            "product_entitlement_mapping": {
                "com.revenuecat.foo_1:monthly": {
                    "product_identifier": "com.revenuecat.foo_1",
                    "base_plan_id": "monthly",
                    "entitlements": [
                        "pro_1"
                    ]
                }
            }
        }
        """.data(using: .utf8))

        let response = try JSONDecoder.default.decode(ProductEntitlementMappingResponse.self, from: data)
        let product = response.products["com.revenuecat.foo_1:monthly"]

        expect(product?.identifier) == "com.revenuecat.foo_1"
        expect(product?.basePlanId) == "monthly"
        expect(product?.entitlements) == ["pro_1"]
    }

    func testConversionToMapping() {
        let mapping = self.response.toMapping()

        expect(mapping.entitlementsByProduct) == [
            "com.revenuecat.foo_1": [
                "pro_1"
            ],
            "com.revenuecat.foo_2": [
                "pro_1",
                "pro_2"
            ],
            "com.revenuecat.foo_3": [
                "pro_2"
            ]
        ]
    }

    func testConversionToMappingUsesBasePlanId() throws {
        let data = try XCTUnwrap("""
        {
            "product_entitlement_mapping": {
                "com.revenuecat.foo_1:monthly": {
                    "product_identifier": "com.revenuecat.foo_1",
                    "base_plan_id": "monthly",
                    "entitlements": [
                        "pro_1"
                    ]
                }
            }
        }
        """.data(using: .utf8))

        let response = try JSONDecoder.default.decode(ProductEntitlementMappingResponse.self, from: data)
        let mapping = response.toMapping()

        expect(mapping.entitlementsByProduct) == [
            "com.revenuecat.foo_1:monthly": [
                "pro_1"
            ]
        ]
    }

    func testDecodesFixtureWithBasePlanIdAndConvertsToCompoundMapping() throws {
        let response: ProductEntitlementMappingResponse = try Self.decodeFixture("ProductsEntitlementsWithBasePlanId")
        let product = response.products["com.revenuecat.foo_1:monthly"]

        expect(product?.identifier) == "com.revenuecat.foo_1"
        expect(product?.basePlanId) == "monthly"
        expect(product?.entitlements) == ["pro_1"]

        expect(response.toMapping().entitlementsByProduct) == [
            "com.revenuecat.foo_1:monthly": [
                "pro_1"
            ],
            "com.revenuecat.foo_2": [
                "pro_2"
            ]
        ]
    }

}
