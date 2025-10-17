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

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PriceFormatterProviderTests: StoreKitConfigTestCase {

    private var priceFormatterProvider: PriceFormatterProvider!

    override func setUp() {
        super.setUp()

        self.priceFormatterProvider = PriceFormatterProvider(priceFormattingRuleSet: nil)
    }

    func testReturnsCachedPriceFormatterForSK1() {
        let locale = Locale(identifier: "en_US")
        let firstPriceFormatter = self.priceFormatterProvider.priceFormatterForSK1(with: locale)

        let secondPriceFormatter = self.priceFormatterProvider.priceFormatterForSK1(with: locale)

        expect(firstPriceFormatter) === secondPriceFormatter
    }

    func testReturnsCachedPriceFormatterForSK2() throws {
        let currencyCode = "USD"
        let firstPriceFormatter = self.priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        let secondPriceFormatter = self.priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: currencyCode)

        expect(firstPriceFormatter) === secondPriceFormatter
    }

    func testSk1PriceFormatterUsesCurrentStorefront() async throws {
        self.testSession.locale = Locale(identifier: "es_ES")
        try await self.changeStorefront("ESP")

        let sk1Fetcher = ProductsFetcherSK1(requestTimeout: Configuration.storeKitRequestTimeoutDefault)

        var storeProduct = try await sk1Fetcher.product(withIdentifier: Self.productID)

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        self.testSession.locale = Locale(identifier: "en_EN")
        try await self.changeStorefront("USA")

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
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.testSession.locale = Locale(identifier: "es_ES")
        try await self.changeStorefront("ESP")

        let sk2Fetcher  = ProductsFetcherSK2(priceFormattingRuleSetProvider: .mock)

        var storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        var priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"

        self.testSession.locale = Locale(identifier: "en_EN")
        try await self.changeStorefront("USA")

        storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "USD"
    }
    
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterCurrencySymbolOverriding() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.testSession.locale = Locale(identifier: "nl_NL")
        try await self.changeStorefront("NLD")

        let sk2Fetcher = ProductsFetcherSK2(
            priceFormattingRuleSetProvider: .init(
                priceFormattingRuleSet: {
                    .init(currencySymbolOverrides: [
                        "EUR": .init(
                            zero: "zero",
                            one: "one",
                            two: "two",
                            few: "few",
                            many: "many",
                            other: "other"
                        )
                    ])
                }
            )
        )

        let storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "EUR"
        expect(priceFormatter.currencySymbol) == "€"
        XCTAssert(type(of: priceFormatter) == CurrencySymbolOverridingPriceFormatter.self)
        
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 0)), "zero 0,00")
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 1)), "one 1,00")
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 2)), "two 2,00")
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 3)), "other 3,00")
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSk2PriceFormatterCurrencySymbolOverridingRomania() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.testSession.locale = Locale(identifier: "ro_RO")
        try await self.changeStorefront("ROU")
        
        let sk2Fetcher = ProductsFetcherSK2(
            priceFormattingRuleSetProvider: .init(
                priceFormattingRuleSet: {
                    .init(currencySymbolOverrides: [
                        "RON": .init(
                            zero: "lei",
                            one: "leu",
                            two: "lei",
                            few: "lei",
                            many: "lei",
                            other: "lei"
                        )
                    ])
                }
            )
        )

        let storeProduct = try await sk2Fetcher.product(withIdentifier: Self.productID)

        let priceFormatter = try XCTUnwrap(storeProduct.priceFormatter)
        expect(priceFormatter.currencyCode) == "RON"
        expect(priceFormatter.currencySymbol) == "RON"
        XCTAssert(type(of: priceFormatter) == CurrencySymbolOverridingPriceFormatter.self)
        
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 0)), "0,00 lei")
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 1)), "1,00 leu")
        XCTAssertEqual(priceFormatter.string(from: NSNumber(integerLiteral: 2)), "2,00 lei")
    }
}

extension PriceFormattingRuleSetProvider {
    static let mock = PriceFormattingRuleSetProvider(priceFormattingRuleSet: { .init(currencySymbolOverrides: [:]) })
}
