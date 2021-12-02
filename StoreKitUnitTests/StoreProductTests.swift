//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class StoreProductTests: StoreKitConfigTestCase {

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2DetailsAreEquivalent() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime"
        ])
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        let sk1StoreProduct = await sk1Fetcher.products(withIdentifiers: productIdentifiers)
        let sk1StoreProductsByID = sk1StoreProduct.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        let sk2Fetcher = ProductsFetcherSK2()
        let sk2StoreProduct = try await sk2Fetcher.products(identifiers: productIdentifiers)
        let sk2StoreProductsByID = sk2StoreProduct.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        expect(sk1StoreProduct.count) == productIdentifiers.count
        expect(sk1StoreProduct.count) == sk2StoreProduct.count

        for sk1ProductID in sk1StoreProductsByID.keys {
            let sk1Product = try XCTUnwrap(sk1StoreProductsByID[sk1ProductID])
            let equivalentSK2Product = try XCTUnwrap(sk2StoreProductsByID[sk1ProductID])

            expect(sk1Product.productIdentifier) == equivalentSK2Product.productIdentifier
            expect(sk1Product.localizedDescription) == equivalentSK2Product.localizedDescription
            expect(sk1Product.price) == equivalentSK2Product.price
            expect(sk1Product.localizedPriceString) == equivalentSK2Product.localizedPriceString
            expect(sk1Product.productIdentifier) == equivalentSK2Product.productIdentifier
            expect(sk1Product.isFamilyShareable) == equivalentSK2Product.isFamilyShareable
            expect(sk1Product.localizedTitle) == equivalentSK2Product.localizedTitle
            if sk1Product.subscriptionGroupIdentifier != nil {
                expect(sk1Product.subscriptionGroupIdentifier) == equivalentSK2Product.subscriptionGroupIdentifier
            } else {
                expect(equivalentSK2Product.subscriptionGroupIdentifier).to(beNil())
            }
        }
    }

    func testSk1DetailsWrapsCorrectly() throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        var callbackCalled = false

        sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { storeProductSet in
            callbackCalled = true
            guard let storeProduct = storeProductSet.first else { fatalError("couldn't get product!") }

            expect(storeProduct.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
            expect(storeProduct.localizedDescription) == "Monthly subscription with a 1-week free trial"
            expect(storeProduct.price.description) == "4.99"
            expect(storeProduct.localizedPriceString) == "$4.99"
            expect(storeProduct.productIdentifier) == productIdentifier
            expect(storeProduct.isFamilyShareable) == true
            expect(storeProduct.localizedTitle) == "Monthly Free Trial"
            // open the StoreKit Config file as source code to see the expected value
            expect(storeProduct.subscriptionGroupIdentifier) == "7096FF06"
        }

        expect(callbackCalled).toEventually(beTrue(), timeout: .seconds(5))
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2DetailsWrapsCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)

        expect(storeProduct.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(storeProduct.localizedDescription) == "Monthly subscription with a 1-week free trial"
        expect(storeProduct.price.description) == "4.99"
        expect(storeProduct.localizedPriceString) == "$4.99"
        expect(storeProduct.productIdentifier) == productIdentifier
        expect(storeProduct.isFamilyShareable) == true
        expect(storeProduct.localizedTitle) == "Monthly Free Trial"
        // open the StoreKit Config file as source code to see the expected value
        expect(storeProduct.subscriptionGroupIdentifier) == "7096FF06"
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterFormatsCorrectly() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)
        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        let productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk1PriceFormatterFormatsCorrectly() async throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk1Fetcher = ProductsFetcherSK1()

        let storeProductSet = await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)
        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        let productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

}
