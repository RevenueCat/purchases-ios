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
        let manager = try createManager(storeKit2Setting: .disabled)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Result<Set<StoreProduct>, Error>?

        manager.products(withIdentifiers: Set([identifier])) { products in
            receivedProducts = products
        }

        expect(receivedProducts).toEventuallyNot(beNil(), timeout: Self.requestDispatchTimeout)
        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())

        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    func testFetchProductsWithIdentifiersSK2() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = try createManager(storeKit2Setting: .enabledForCompatibleDevices)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Result<Set<StoreProduct>, Error>?

        manager.products(withIdentifiers: Set([identifier])) { products in
            receivedProducts = products
        }

        expect(receivedProducts).toEventuallyNot(beNil(), timeout: Self.requestDispatchTimeout)
        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())

        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    func testInvalidateAndReFetchCachedProductsAfterStorefrontChangesSK1() async throws {
        let manager = try createManager(storeKit2Setting: .disabled)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        var unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "USD"

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        // Note: this test passes only because the method `invalidateAndReFetchCachedProductsIfAppropiate`
        // is manually executed. `ProductsManager` does not detect Storefront changes to invalidate the
        // cache. The changes are now managed by `StoreKit2StorefrontListenerDelegate`.
        manager.invalidateAndReFetchCachedProductsIfAppropiate()

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "EUR"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testInvalidateAndReFetchCachedProductsAfterStorefrontChangesSK2() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let manager = try createManager(storeKit2Setting: .enabledForCompatibleDevices)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        var unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "USD"

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        // Note: this test passes only because the method `invalidateAndReFetchCachedProductsIfAppropiate`
        // is manually executed. `ProductsManager` does not detect Storefront changes to invalidate the
        // cache. The changes are now managed by `StoreKit2StorefrontListenerDelegate`.
        manager.invalidateAndReFetchCachedProductsIfAppropiate()

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "EUR"
    }

    private func createManager(storeKit2Setting: StoreKit2Setting) throws -> ProductsManager {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        return ProductsManager(
            systemInfo: try MockSystemInfo(
                platformInfo: platformInfo,
                finishTransactions: true,
                storeKit2Setting: storeKit2Setting
            ),
            requestTimeout: Self.requestTimeout
        )
    }

}
