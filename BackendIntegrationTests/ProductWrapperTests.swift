//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductWrapperTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Nimble
import StoreKitTest
import XCTest
@testable import Purchases

class ProductsWrapperTests: XCTestCase {

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.disableDialogs = true
        testSession.clearTransactions()
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2WrappersAreEquivalent() async throws {
        #if arch(arm64)

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime",
            ])
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        let sk1ProductWrappers = await sk1Fetcher.products(withIdentifiers: productIdentifiers)
        let sk1ProductWrappersByID = sk1ProductWrappers.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        let sk2Fetcher = ProductsFetcherSK2()
        let sk2ProductWrappers = try await sk2Fetcher.products(identifiers: productIdentifiers)
        let sk2ProductWrappersByID = sk2ProductWrappers.reduce(into: [:]) { partialResult, wrapper in
            partialResult[wrapper.productIdentifier] = wrapper
        }

        expect(sk1ProductWrappers.count) == productIdentifiers.count
        expect(sk1ProductWrappers.count) == sk2ProductWrappers.count

        for sk1ProductID in sk1ProductWrappersByID.keys {
            let sk1Product = try XCTUnwrap(sk1ProductWrappersByID[sk1ProductID])
            let equivalentSK2Product = try XCTUnwrap(sk2ProductWrappersByID[sk1ProductID])

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

    func testSk1WrapperWrappsCorrectly() throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory())
        var callbackCalled = false

        sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { productWrappers in
            callbackCalled = true
            guard let productWrapper = productWrappers.first else { fatalError("couldn't get product!") }

            expect(productWrapper.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
            expect(productWrapper.localizedDescription) == "Monthly subscription with a 1-week free trial"
            expect(productWrapper.price.description) == "4.99"
            expect(productWrapper.localizedPriceString) == "$4.99"
            expect(productWrapper.productIdentifier) == productIdentifier
            expect(productWrapper.isFamilyShareable) == true
            expect(productWrapper.localizedTitle) == "Monthly Free Trial"
        }

        expect(callbackCalled).toEventually(beTrue())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2WrapperWrappsCorrectly() async throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let productWrappers = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let productWrapper = try XCTUnwrap(productWrappers.first)

        expect(productWrapper.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(productWrapper.localizedDescription) == "Monthly subscription with a 1-week free trial"
        expect(productWrapper.price.description) == "4.99"
        expect(productWrapper.localizedPriceString) == "$4.99"
        expect(productWrapper.productIdentifier) == productIdentifier
        expect(productWrapper.isFamilyShareable) == true
        expect(productWrapper.localizedTitle) == "Monthly Free Trial"

    }

}
