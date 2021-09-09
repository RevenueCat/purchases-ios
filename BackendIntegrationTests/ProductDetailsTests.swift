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
import StoreKitTest
import XCTest
@testable import RevenueCat

class ProductsWrapperTests: XCTestCase {

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.disableDialogs = true
        testSession.clearTransactions()
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2DetailsAreEquivalent() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else { return }

        #if arch(arm64)

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime",
            ])
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        let sk1ProductDetailss = await sk1Fetcher.products(withIdentifiers: productIdentifiers)
        let sk1ProductDetailssByID = sk1ProductDetailss.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        let sk2Fetcher = ProductsFetcherSK2()
        let sk2ProductDetailss = try await sk2Fetcher.products(identifiers: productIdentifiers)
        let sk2ProductDetailssByID = sk2ProductDetailss.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        expect(sk1ProductDetailss.count) == productIdentifiers.count
        expect(sk1ProductDetailss.count) == sk2ProductDetailss.count

        for sk1ProductID in sk1ProductDetailssByID.keys {
            let sk1Product = try XCTUnwrap(sk1ProductDetailssByID[sk1ProductID])
            let equivalentSK2Product = try XCTUnwrap(sk2ProductDetailssByID[sk1ProductID])

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
        #endif
    }

    func testSk1DetailsWrapsCorrectly() throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        var callbackCalled = false

        sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { productDetailss in
            callbackCalled = true
            guard let productDetails = productDetailss.first else { fatalError("couldn't get product!") }

            expect(productDetails.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
            expect(productDetails.localizedDescription) == "Monthly subscription with a 1-week free trial"
            expect(productDetails.price.description) == "4.99"
            expect(productDetails.localizedPriceString) == "$4.99"
            expect(productDetails.productIdentifier) == productIdentifier
            expect(productDetails.isFamilyShareable) == true
            expect(productDetails.localizedTitle) == "Monthly Free Trial"
        }

        expect(callbackCalled).toEventually(beTrue())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2DetailsWrapsCorrectly() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else { return }

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let productDetailss = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let productDetails = try XCTUnwrap(productDetailss.first)

        expect(productDetails.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(productDetails.localizedDescription) == "Monthly subscription with a 1-week free trial"
        expect(productDetails.price.description) == "4.99"
        expect(productDetails.localizedPriceString) == "$4.99"
        expect(productDetails.productIdentifier) == productIdentifier
        expect(productDetails.isFamilyShareable) == true
        expect(productDetails.localizedTitle) == "Monthly Free Trial"

    }

}
