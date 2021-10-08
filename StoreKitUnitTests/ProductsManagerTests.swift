//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerTests.swift
//
//  Created by Andrés Boedo on 7/23/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
class ProductsManagerTests: StoreKitConfigTestCase {

    var productsManager: ProductsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        productsManager = ProductsManager()
    }

    func testFetchProductsFromOptimalStoreKitVersion() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var maybeReceivedProducts: Set<ProductDetails>?

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: Set([identifier]), completion: { products in
            completionCalled = true
            maybeReceivedProducts = products
        })

        expect(completionCalled).toEventually(beTrue())
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == 1

        let firstProduct = try XCTUnwrap(receivedProducts.first)

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *),
            SystemInfo.useStoreKit2IfAvailable {
            expect(firstProduct as? SK2ProductDetails).toNot(beNil())
        } else {
            expect(firstProduct as? SK1ProductDetails).toNot(beNil())
        }
        expect(firstProduct.productIdentifier) == identifier
    }
}
