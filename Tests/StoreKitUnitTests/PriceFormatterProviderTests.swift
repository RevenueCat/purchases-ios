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
        let firstPriceFormatter = self.priceFormatterProvider.priceFormatterForSK1(with: locale)

        let secondPriceFormatter = self.priceFormatterProvider.priceFormatterForSK1(with: locale)

        expect(firstPriceFormatter) === secondPriceFormatter
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testReturnsCachedPriceFormatterForSK2() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let currencyCode = "USD"
        let firstPriceFormatter = self.priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        let secondPriceFormatter = self.priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        expect(firstPriceFormatter) === secondPriceFormatter
    }

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    func testSk1PriceFormatterUsesCurrentStorefront() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.testSession.locale = Locale(identifier: "es_ES")
        await self.changeStorefront("ESP")

        let sk1Fetcher = ProductsFetcherSK1(requestTimeout: Configuration.storeKitRequestTimeoutDefault)

        var storeProduct = try await sk1Fetcher.product(withIdentifier: Self.productID)

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        self.testSession.locale = Locale(identifier: "en_EN")
        await self.changeStorefront("USA")

        // Note: this test passes only because the cache is manually
        // cleared. `ProductsFetcherSK1` does not detect Storefront
        // changes to invalidate the cache. The changes are now managed by
        // `StoreKit2StorefrontListenerDelegate`.
        sk1Fetcher.clearCache()

        storeProduct = try await sk1Fetcher.product(withIdentifier: Self.productID)

        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "USD"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterUsesCurrentStorefront() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.testSession.locale = Locale(identifier: "es_ES")
        await self.changeStorefront("ESP")

        let sk2Fetcher = ProductsFetcherSK2()

        var storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        self.testSession.locale = Locale(identifier: "en_EN")
        await self.changeStorefront("USA")

        // Note: this test passes only because the cache is manually
        // cleared. `ProductsFetcherSK2` does not detect Storefront
        // changes to invalidate the cache. The changes are now managed by
        // `StoreKit2StorefrontListenerDelegate`.
        await sk2Fetcher.clearCache()

        storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "USD"
    }

}
