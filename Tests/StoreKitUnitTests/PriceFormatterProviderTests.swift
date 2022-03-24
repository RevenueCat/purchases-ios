//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceFormatterProviderTests.swift
//
//  Created by Juanpe Catalán on 10/3/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PriceFormatterProviderTests: StoreKitConfigTestCase {

    private var priceFormatterProvider: PriceFormatterProvider!

    override func setUp() {
        super.setUp()

        self.priceFormatterProvider = PriceFormatterProvider()
    }

    func testReturnsCachedPriceFormatterForSK1() {
        let locale = Locale(identifier: "en_US")
        let firstPriceFormatter = priceFormatterProvider.priceFormatterForSK1(with: locale)

        let secondPriceFormatter = priceFormatterProvider.priceFormatterForSK1(with: locale)

        XCTAssertIdentical(firstPriceFormatter, secondPriceFormatter)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testReturnsCachedPriceFormatterForSK2() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let currencyCode = "USD"
        let firstPriceFormatter = priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        let secondPriceFormatter = priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        XCTAssertIdentical(firstPriceFormatter, secondPriceFormatter)
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func testSk1PriceFormatterUsesCurrentStorefront() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        var sk1Fetcher = ProductsFetcherSK1()

        var storeProduct = try await sk1Fetcher.product(withIdentifier: Self.productID)

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        testSession.locale = Locale(identifier: "en_EN")
        await changeStorefront("USA")

        // Note: this test passes only because the fetcher is recreated
        // therefore clearing the cache. `ProductsFetcherSK1` does not
        // detect Storefront changes to invalidate the cache like `ProductsFetcherSK2` does.
        sk1Fetcher = ProductsFetcherSK1()

        storeProduct = try await sk1Fetcher.product(withIdentifier: Self.productID)

        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "USD"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterUsesCurrentStorefront() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "es_ES")
        await changeStorefront("ESP")

        var storeProduct = try await fetchSk2StoreProduct()

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        testSession.locale = Locale(identifier: "en_EN")
        await changeStorefront("USA")

        storeProduct = try await fetchSk2StoreProduct()

        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "USD"
    }

}
