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

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2DetailsAreEquivalent() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime"
        ])
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory(),
                                            requestTimeout: Self.requestTimeout)
        let sk1StoreProduct = try await sk1Fetcher.products(withIdentifiers: productIdentifiers)
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
        let sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory(),
                                            requestTimeout: Self.requestTimeout)
        var result: Result<Set<StoreProduct>, Error>!

        sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { products in
            result = products
        }

        expect(result).toEventuallyNot(beNil(), timeout: Self.requestTimeout + .seconds(5))

        let products = try result.get()
        expect(products).to(haveCount(1))
        let storeProduct = try XCTUnwrap(products.first)

        expect(storeProduct.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(storeProduct.localizedDescription) == "Monthly subscription with a 1-week free trial"
        expect(storeProduct.price.description) == "4.99"
        expect(storeProduct.localizedPriceString) == "$4.99"
        expect(storeProduct.productIdentifier) == productIdentifier
        expect(storeProduct.isFamilyShareable) == true
        expect(storeProduct.localizedTitle) == "Monthly Free Trial"
        // open the StoreKit Config file as source code to see the expected value
        expect(storeProduct.subscriptionGroupIdentifier) == "7096FF06"

        expect(storeProduct.subscriptionPeriod?.unit) == .month
        expect(storeProduct.subscriptionPeriod?.value) == 1

        let intro = try XCTUnwrap(storeProduct.introductoryPrice)

        expect(intro.price) == 0.0
        expect(intro.paymentMode) == .freeTrial
        expect(intro.offerIdentifier).to(beNil())
        expect(intro.subscriptionPeriod) == SubscriptionPeriod(value: 3, unit: .month)

        let offers = try XCTUnwrap(storeProduct.discounts)
        expect(offers).to(haveCount(2))

        expect(offers[0].price) == 40.99
        expect(offers[0].paymentMode) == .payUpFront
        expect(offers[0].offerIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro.year_discount"
        expect(offers[0].subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)

        expect(offers[1].price) == 20.15
        expect(offers[1].paymentMode) == .payAsYouGo
        expect(offers[1].offerIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro.pay_as_you_go"

        expect(offers[1].subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .month)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2DetailsWrapsCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        expect(storeProductSet).to(haveCount(1))

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

        expect(storeProduct.subscriptionPeriod?.unit) == .month
        expect(storeProduct.subscriptionPeriod?.value) == 1

        let intro = try XCTUnwrap(storeProduct.introductoryPrice)

        expect(intro.price) == 0.0
        expect(intro.paymentMode) == .freeTrial
        expect(intro.offerIdentifier).to(beNil())
        expect(intro.subscriptionPeriod) == SubscriptionPeriod(value: 3, unit: .month)

        let offers = try XCTUnwrap(storeProduct.discounts)
        expect(offers).to(haveCount(2))

        expect(offers[0].price) == 40.99
        expect(offers[0].paymentMode) == .payUpFront
        expect(offers[0].offerIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro.year_discount"
        expect(offers[0].subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)

        expect(offers[1].price) == 20.15
        expect(offers[1].paymentMode) == .payAsYouGo
        expect(offers[1].offerIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro.pay_as_you_go"

        expect(offers[1].subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .month)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterFormatsCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk2Fetcher = ProductsFetcherSK2()

        let storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)
        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        let productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
    func testSk1PriceFormatterFormatsCorrectly() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let sk1Fetcher = ProductsFetcherSK1()

        let storeProductSet = try await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)
        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        let productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
    func testSk1PriceFormatterReactsToStorefrontChanges() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        testSession.storefront = "ESP"

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var sk1Fetcher = ProductsFetcherSK1()

        var storeProductSet = try await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        var storeProduct = try XCTUnwrap(storeProductSet.first)
        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        var productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "4,99 €"

        testSession.locale = Locale(identifier: "en_EN")
        testSession.storefront = "USA"

        sk1Fetcher = ProductsFetcherSK1()

        storeProductSet = try await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        storeProduct = try XCTUnwrap(storeProductSet.first)
        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"

        testSession.locale = Locale(identifier: "es_ES")
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterReactsToStorefrontChanges() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        testSession.storefront = "ESP"

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var sk2Fetcher = ProductsFetcherSK2()

        var storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        var storeProduct = try XCTUnwrap(storeProductSet.first)
        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        var productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "€4.99"

        testSession.locale = Locale(identifier: "en_EN")
        testSession.storefront = "USA"

        sk2Fetcher = ProductsFetcherSK2()

        storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        storeProduct = try XCTUnwrap(storeProductSet.first)
        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"

        testSession.locale = Locale(identifier: "es_ES")
    }

}
