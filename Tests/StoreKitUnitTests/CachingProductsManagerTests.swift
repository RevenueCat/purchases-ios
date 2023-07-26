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
//  Created by Nacho Soto on 7/26/23.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class CachingProductsManagerIntegrationTests: StoreKitConfigTestCase {

    func testFetchProductsWithIdentifiersSK1() throws {
        let manager = Self.createManager(.disabled)

        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchProductsWithIdentifiersSK2() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = Self.createManager(.enabledForCompatibleDevices)

        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchCachedSK1Products() throws {
        let manager = Self.createManager(.disabled)

        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.offering.products_already_cached(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchCachedSK2Products() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = Self.createManager(.enabledForCompatibleDevices)

        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.offering.products_already_cached(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension CachingProductsManagerIntegrationTests {

    static func createManager(_ setting: StoreKit2Setting) -> ProductsManagerType {
        return CachingProductsManager(
            manager:
                ProductsManager(
                    systemInfo: MockSystemInfo(
                        finishTransactions: true,
                        storeKit2Setting: setting
                    ),
                    requestTimeout: Self.requestTimeout
                )
        )
    }

}
