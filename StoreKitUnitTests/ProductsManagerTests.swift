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

// - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
// Although the method isn't supposed to be called because of our @available marks,
// everything in this class will still be called by XCTest, and it will cause errors.
@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
class ProductsManagerTests: StoreKitConfigTestCase {

    var productsManager: ProductsManager!
    var systemInfo: MockSystemInfo!

    private static let defaultTimeout: DispatchTimeInterval = .seconds(30)

    override func setUpWithError() throws {
        try super.setUpWithError()
        systemInfo = try MockSystemInfo(platformFlavor: "xyz", platformFlavorVersion: "123", finishTransactions: true)
        productsManager = ProductsManager(systemInfo: systemInfo, requestTimeout: Self.defaultTimeout)
    }

    func testFetchProductsFromOptimalStoreKitVersion() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var maybeReceivedProducts: Set<StoreProduct>?

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: Set([identifier]), completion: { products in
            completionCalled = true
            maybeReceivedProducts = products
        })

        expect(completionCalled).toEventually(beTrue(), timeout: Self.defaultTimeout)
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == 1

        let firstProduct = try XCTUnwrap(receivedProducts.first)

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *),
            systemInfo.useStoreKit2IfAvailable {
            expect(firstProduct as? SK2StoreProduct).toNot(beNil())
        } else {
            expect(firstProduct as? SK1StoreProduct).toNot(beNil())
        }
        expect(firstProduct.productIdentifier) == identifier
    }

    func testFetchProductsFromOptimalStoreKitVersionPrefersSK2IfUseSK2WhenAvailableEnabled() throws {

        systemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                        platformFlavorVersion: "123",
                                        finishTransactions: true,
                                        useStoreKit2IfAvailable: true)
        productsManager = ProductsManager(systemInfo: systemInfo, requestTimeout: Self.defaultTimeout)

        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var maybeReceivedProducts: Set<StoreProduct>?

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: Set([identifier]), completion: { products in
            completionCalled = true
            maybeReceivedProducts = products
        })

        expect(completionCalled).toEventually(beTrue(), timeout: Self.defaultTimeout)
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == 1

        let firstProduct = try XCTUnwrap(receivedProducts.first)

        expect(firstProduct).to(beAnInstanceOf(SK2StoreProduct.self))
    }

    func testFetchProductsFromOptimalStoreKitVersionPrefersSK1ByDefault() throws {

        systemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                        platformFlavorVersion: "123",
                                        finishTransactions: true)
        productsManager = ProductsManager(systemInfo: systemInfo, requestTimeout: Self.defaultTimeout)

        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 7.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var maybeReceivedProducts: Set<StoreProduct>?

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: Set([identifier]), completion: { products in
            completionCalled = true
            maybeReceivedProducts = products
        })

        expect(completionCalled).toEventually(beTrue(), timeout: Self.defaultTimeout)
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == 1

        let firstProduct = try XCTUnwrap(receivedProducts.first)

        expect(firstProduct as? SK1StoreProduct).toNot(beNil())
        expect(firstProduct).to(beAnInstanceOf(SK1StoreProduct.self))
    }

}
