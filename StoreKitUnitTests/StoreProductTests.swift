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

    private var sk1Fetcher: ProductsFetcherSK1!

    override func setUp() {
        super.setUp()

        self.sk1Fetcher = ProductsFetcherSK1(productsRequestFactory: ProductsRequestFactory(),
                                             requestTimeout: Self.requestTimeout)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1AndSK2DetailsAreEquivalent() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro",
            "com.revenuecat.annual_39.99.2_week_intro",
            "lifetime"
        ])
        let sk1StoreProducts = try await self.sk1Fetcher.products(withIdentifiers: productIdentifiers)
        let sk1StoreProductsByID = sk1StoreProducts.dictionaryWithKeys { $0.productIdentifier }

        let sk2StoreProducts = try await ProductsFetcherSK2().products(identifiers: productIdentifiers)
        let sk2StoreProductsByID = sk2StoreProducts.dictionaryWithKeys { $0.productIdentifier }

        expect(sk1StoreProducts.count) == productIdentifiers.count
        expect(sk1StoreProducts.count) == sk2StoreProducts.count

        for sk1ProductID in sk1StoreProductsByID.keys {
            let sk1Product = try XCTUnwrap(sk1StoreProductsByID[sk1ProductID])
            let equivalentSK2Product = try XCTUnwrap(sk2StoreProductsByID[sk1ProductID])

            expectEqualProducts(sk1Product, equivalentSK2Product)
        }
    }

    func testSK1AndStoreProductDetailsAreEquivalent() async throws {
        let products = try await self.sk1Fetcher.products(withIdentifiers: ["com.revenuecat.monthly_4.99.1_week_intro"])
        let product = try XCTUnwrap(products.first)

        expectEqualProducts(product, StoreProduct.from(product: product))
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2AndStoreProductDetailsAreEquivalent() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let products = try await ProductsFetcherSK2()
            .products(identifiers: ["com.revenuecat.monthly_4.99.1_week_intro"])
        let product = try XCTUnwrap(products.first)

        expectEqualProducts(product, StoreProduct.from(product: product))
    }

    func testSk1DetailsWrapsCorrectly() throws {
        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var result: Result<Set<SK1StoreProduct>, Error>!

        self.sk1Fetcher.products(withIdentifiers: Set([productIdentifier])) { products in
            result = products
        }

        expect(result).toEventuallyNot(beNil(), timeout: Self.requestTimeout + .seconds(5))

        let products = try result.get()
        expect(products).to(haveCount(1))

        let sk1Product = try XCTUnwrap(products.first)
        let storeProduct = StoreProduct.from(product: sk1Product)

        expect(storeProduct.sk1Product) === sk1Product.underlyingSK1Product

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

        let intro = try XCTUnwrap(storeProduct.introductoryDiscount)

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

        let sk2Product = try XCTUnwrap(storeProductSet.first)
        let storeProduct = StoreProduct.from(product: sk2Product)

        // Can't use `===` because `SK2Product` is a `struct`
        expect(storeProduct.sk2Product) == sk2Product.underlyingSK2Product

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

        let intro = try XCTUnwrap(storeProduct.introductoryDiscount)

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
        expect(storeProduct.localizedPriceString) == "$4.99"
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func testSk1PriceFormatterFormatsCorrectly() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"

        let storeProductSet = try await self.sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        let storeProduct = try XCTUnwrap(storeProductSet.first)
        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        let productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
        expect(storeProduct.localizedPriceString) == "$4.99"
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func testSk1PriceFormatterUsesCurrentStorefront() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var sk1Fetcher = ProductsFetcherSK1()

        var storeProductSet = try await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        var storeProduct = try XCTUnwrap(storeProductSet.first)
        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        var productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "4,99 €"

        testSession.locale = Locale(identifier: "en_EN")
        await changeStorefront("USA")

        // Note: this test passes only because the fetcher is recreated
        // therefore clearing the cache. `ProductsFetcherSK1` does not
        // detect Storefront changes to invalidate the cache like `ProductsFetcherSK2` does.
        sk1Fetcher = ProductsFetcherSK1()

        storeProductSet = try await sk1Fetcher.products(withIdentifiers: Set([productIdentifier]))

        storeProduct = try XCTUnwrap(storeProductSet.first)
        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterReactsToStorefrontChanges() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        let sk2Fetcher = ProductsFetcherSK2()

        let productIdentifier = "com.revenuecat.monthly_4.99.1_week_intro"

        var storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        var storeProduct = try XCTUnwrap(storeProductSet.first)
        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        var productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "€4.99"

        testSession.locale = Locale(identifier: "en_EN")
        await changeStorefront("USA")

        storeProductSet = try await sk2Fetcher.products(identifiers: Set([productIdentifier]))

        storeProduct = try XCTUnwrap(storeProductSet.first)
        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        productPrice = storeProduct.price as NSNumber

        expect(priceFormatter.string(from: productPrice)) == "$4.99"
    }

    private func expectEqualProducts(_ productA: StoreProductType, _ productB: StoreProductType) {
        expect(productA.productIdentifier) == productB.productIdentifier
        expect(productA.localizedDescription) == productB.localizedDescription
        expect(productA.price) == productB.price
        expect(productA.localizedPriceString) == productB.localizedPriceString
        expect(productA.productIdentifier) == productB.productIdentifier
        expect(productA.isFamilyShareable) == productB.isFamilyShareable
        expect(productA.localizedTitle) == productB.localizedTitle

        expect(productA.isFamilyShareable) == productB.isFamilyShareable

        expect(productA.discounts) == productB.discounts

        if productA.subscriptionPeriod == nil {
            expect(productB.subscriptionPeriod).to(beNil())
        } else {
            expect(productA.subscriptionPeriod) == productB.subscriptionPeriod
        }

        if productA.introductoryDiscount == nil {
            expect(productB.introductoryDiscount).to(beNil())
        } else {
            expect(productA.introductoryDiscount) == productB.introductoryDiscount
        }

        if productA.subscriptionGroupIdentifier == nil {
            expect(productB.subscriptionGroupIdentifier).to(beNil())
        } else {
            expect(productA.subscriptionGroupIdentifier) == productB.subscriptionGroupIdentifier
        }
    }

    /// Updates `SKTestSession.storefront` and waits for `Storefront.current` to reflect the change
    /// This is necessary because the change is aynchronous within `StoreKit`, and otherwise code that depends
    /// on the change might not see it in time, resulting in race conditions and flaky tests.
    private func changeStorefront(_ new: String) async {
        testSession.storefront = new

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // Note: a better approach would be using `XCTestExpectation` and `self.wait(for:timeout:)`
            // but it doesn't seem to play well with async-await.
            // Also `toEventually` (Quick nor Nimble) don't support `async`.

            var storefrontUpdateDetected: Bool {
                get async { await Storefront.current?.countryCode == new }
            }

            var numberOfChecksLeft = 10

            repeat {
                if await !storefrontUpdateDetected {
                    numberOfChecksLeft -= 1
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                } else {
                    break
                }
            } while numberOfChecksLeft > 0

            let detected = await storefrontUpdateDetected
            expect(detected).to(beTrue(), description: "Storefront change not detected")
        }
    }
}
