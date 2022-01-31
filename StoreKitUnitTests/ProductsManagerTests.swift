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

    func testFetchProductsWithIdentifiersSK1() throws {
        let manager = try createManager(useStoreKit2IfAvailable: false)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var receivedProducts: Result<Set<StoreProduct>, Error>?

        manager.products(withIdentifiers: Set([identifier])) { products in
            completionCalled = true
            receivedProducts = products
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.requestTimeout)
        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        expect(unwrappedProducts.count) == 1

        let product = try XCTUnwrap(unwrappedProducts.first).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    func testFetchProductsWithIdentifiersSK2() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = try createManager(useStoreKit2IfAvailable: true)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var receivedProducts: Result<Set<StoreProduct>, Error>?

        manager.products(withIdentifiers: Set([identifier])) { products in
            completionCalled = true
            receivedProducts = products
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.requestTimeout)
        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        expect(unwrappedProducts.count) == 1

        let product = try XCTUnwrap(unwrappedProducts.first).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    private func createManager(useStoreKit2IfAvailable: Bool) throws -> ProductsManager {
        return ProductsManager(
            systemInfo: try MockSystemInfo(
                platformFlavor: "xyz",
                platformFlavorVersion: "123",
                finishTransactions: true,
                useStoreKit2IfAvailable: useStoreKit2IfAvailable
            ),
            requestTimeout: Self.requestTimeout
        )
    }

}
