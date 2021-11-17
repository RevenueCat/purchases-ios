//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductDetailsTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class ProductDetailsTests: StoreKitConfigTestCase {

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2DetailsAreEquivalent() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime"
        ])
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        let sk1ProductDetails = await sk1Fetcher.products(withIdentifiers: productIdentifiers)
        let sk1ProductDetailsByID = sk1ProductDetails.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        let sk2Fetcher = ProductsFetcherSK2()
        let sk2ProductDetails = try await sk2Fetcher.products(identifiers: productIdentifiers)
        let sk2ProductDetailsByID = sk2ProductDetails.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        expect(sk1ProductDetails.count) == productIdentifiers.count
        expect(sk1ProductDetails.count) == sk2ProductDetails.count

        for sk1ProductID in sk1ProductDetailsByID.keys {
            let sk1Product = try XCTUnwrap(sk1ProductDetailsByID[sk1ProductID])
            let equivalentSK2Product = try XCTUnwrap(sk2ProductDetailsByID[sk1ProductID])

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

        sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { productDetailsSet in
            callbackCalled = true
            guard let productDetails = productDetailsSet.first else { fatalError("couldn't get product!") }

            expect(productDetails.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
            expect(productDetails.localizedDescription) == "Monthly subscription with a 1-week free trial"
            expect(productDetails.price.description) == "4.99"
            expect(productDetails.localizedPriceString) == "$4.99"
            expect(productDetails.productIdentifier) == productIdentifier
            expect(productDetails.isFamilyShareable) == true
            expect(productDetails.localizedTitle) == "Monthly Free Trial"
            // open the StoreKit Config file as source code to see the expected value
            expect(productDetails.subscriptionGroupIdentifier) == "7096FF06"
        }

        expect(callbackCalled).toEventually(beTrue(), timeout: .seconds(5))
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2DetailsWrapsCorrectly() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let productDetailsSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let productDetails = try XCTUnwrap(productDetailsSet.first)

        expect(productDetails.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(productDetails.localizedDescription) == "Monthly subscription with a 1-week free trial"
        expect(productDetails.price.description) == "4.99"
        expect(productDetails.localizedPriceString) == "$4.99"
        expect(productDetails.productIdentifier) == productIdentifier
        expect(productDetails.isFamilyShareable) == true
        expect(productDetails.localizedTitle) == "Monthly Free Trial"
        // open the StoreKit Config file as source code to see the expected value
        expect(productDetails.subscriptionGroupIdentifier) == "7096FF06"
    }

}
