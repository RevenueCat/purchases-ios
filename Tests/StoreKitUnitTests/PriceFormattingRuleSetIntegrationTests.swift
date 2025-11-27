//
//  PriceFormattingRuleSetIntegrationTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 21/10/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Nimble
@_spi(Internal)
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PriceFormattingRuleSetIntegrationTests: StoreKitConfigTestCase {

    var mockSystemInfo: MockSystemInfo!
    var mockDeviceCache: MockDeviceCache!
    var mockBackend: MockBackend!
    var mockOfferingsAPI: MockOfferingsAPI!
    let mockOfferingsFactory = MockOfferingsFactory()
    let mockOperationDispatcher = MockOperationDispatcher()
    var offeringsManager: OfferingsManager!
    let preferredLocalesProvider: PreferredLocalesProvider = .mock(locales: ["en_US"])

    func testPriceFormattingRuleSetWithRomanianCurrencySK1() async throws {
        try await testPriceFormattingRuleSetWithRomanianCurrency(storeKitVersion: .storeKit1)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testPriceFormattingRuleSetWithRomanianCurrencySK2() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        try await testPriceFormattingRuleSetWithRomanianCurrency(storeKitVersion: .storeKit2)
    }

    func testPriceFormatterWithoutRuleSetUsesDefaultFormatterSK1() async throws {
        try await testPriceFormatterWithoutRuleSetUsesDefaultFormatter(storeKitVersion: .storeKit1)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testPriceFormatterWithoutRuleSetUsesDefaultFormatterSK2() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        try await testPriceFormatterWithoutRuleSetUsesDefaultFormatter(storeKitVersion: .storeKit2)
    }

    func testDiscountPriceFormattingWithRuleSetSK1() async throws {
        try await testDiscountPriceFormattingWithRuleSet(storeKitVersion: .storeKit1)
    }

    private func testPriceFormattingRuleSetWithRomanianCurrency(storeKitVersion: StoreKitVersion) async throws {
        testSession.locale = Locale(identifier: "ro_RO")

        try await changeStorefront("ROU")

        // Use ROU (Romania's ISO 3166-1 Alpha-3 country code) to match the rule set key
        let manager = try createSut(storeKitVersion: storeKitVersion, storefront: MockStorefront(countryCode: "ROU"))

        let offeringsResponse = OfferingsResponse(
            currentOfferingId: "default",
            offerings: [.init(
                identifier: "default",
                description: "Default offering",
                packages: [
                    .init(
                        identifier: "monthly",
                        platformProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro",
                        webCheckoutUrl: nil
                    )
                ],
                webCheckoutUrl: nil
            )],
            placements: nil,
            targeting: nil,
            uiConfig: .init(
                app: .init(colors: [:], fonts: [:]),
                localizations: [:],
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
            ),
            config: .init(priceFormattingRuleSets: [
                // Use ROU to match the storefront country code
                "ROU": .init(currencySymbolOverrides: [
                    "RON": .init(
                        zero: "lei",
                        one: "leu",
                        two: "lei",
                        few: "lei",
                        many: "lei",
                        other: "lei"
                    )
                ])
            ])
        )

        mockOfferingsAPI.stubbedGetOfferingsCompletionResult = .success(
            .init(response: offeringsResponse, httpResponseOriginalSource: .mainServer)
        )

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: "") {
                completed($0)
            }
        }

        mockDeviceCache.stubbedOfferings = result?.value

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        let unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "RON"

        let unwrappedPriceFormatter = try XCTUnwrap(unwrappedFirstProduct.priceFormatter)
        XCTAssert(type(of: unwrappedPriceFormatter) == CurrencySymbolOverridingPriceFormatter.self)
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 0))) == "0,00 lei"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 1))) == "1,00 leu"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 2))) == "2,00 lei"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 0.25))) == "0,25 lei"
    }

    private func testPriceFormatterWithoutRuleSetUsesDefaultFormatter(storeKitVersion: StoreKitVersion) async throws {
        testSession.locale = Locale(identifier: "ro_RO")

        try await changeStorefront("ROU")
        let manager = try createSut(storeKitVersion: storeKitVersion, storefront: MockStorefront(countryCode: "ROU"))

        // Create offerings response without priceFormattingRuleSets
        let offeringsResponse = OfferingsResponse(
            currentOfferingId: "default",
            offerings: [.init(
                identifier: "default",
                description: "Default offering",
                packages: [
                    .init(
                        identifier: "monthly",
                        platformProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro",
                        webCheckoutUrl: nil
                    )
                ],
                webCheckoutUrl: nil
            )],
            placements: nil,
            targeting: nil,
            uiConfig: .init(
                app: .init(colors: [:], fonts: [:]),
                localizations: [:],
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
            ),
            config: .init(priceFormattingRuleSets: [:])
        )

        mockOfferingsAPI.stubbedGetOfferingsCompletionResult = .success(
            .init(response: offeringsResponse, httpResponseOriginalSource: .mainServer)
        )

        // when
        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: "") {
                completed($0)
            }
        }

        mockDeviceCache.stubbedOfferings = result?.value

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        let unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "RON"

        let unwrappedPriceFormatter = try XCTUnwrap(unwrappedFirstProduct.priceFormatter)
        // Should be a regular NumberFormatter
        XCTAssert(type(of: unwrappedPriceFormatter) == NumberFormatter.self)
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 0))) == "0,00 RON"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 1))) == "1,00 RON"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 2))) == "2,00 RON"
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(value: 0.25))) == "0,25 RON"
    }

    private func testDiscountPriceFormattingWithRuleSet(storeKitVersion: StoreKitVersion) async throws {
        testSession.locale = Locale(identifier: "ro_RO")

        try await changeStorefront("ROU")

        let manager = try createSut(storeKitVersion: storeKitVersion, storefront: MockStorefront(countryCode: "ROU"))

        let offeringsResponse = OfferingsResponse(
            currentOfferingId: "default",
            offerings: [.init(
                identifier: "default",
                description: "Default offering",
                packages: [
                    .init(
                        identifier: "monthly",
                        platformProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro",
                        webCheckoutUrl: nil
                    )
                ],
                webCheckoutUrl: nil
            )],
            placements: nil,
            targeting: nil,
            uiConfig: .init(
                app: .init(colors: [:], fonts: [:]),
                localizations: [:],
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
            ),
            config: .init(priceFormattingRuleSets: [
                "ROU": .init(currencySymbolOverrides: [
                    "RON": .init(
                        zero: "lei",
                        one: "leu",
                        two: "lei",
                        few: "lei",
                        many: "lei",
                        other: "lei"
                    )
                ])
            ])
        )

        mockOfferingsAPI.stubbedGetOfferingsCompletionResult = .success(
            .init(response: offeringsResponse, httpResponseOriginalSource: .mainServer)
        )

        let result = waitUntilValue { completed in
            self.offeringsManager.offerings(appUserID: "") {
                completed($0)
            }
        }

        mockDeviceCache.stubbedOfferings = result?.value

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        let unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "RON"

        // Test introductory discount (free trial, price 0.0)
        if let introductoryDiscount = unwrappedFirstProduct.introductoryDiscount {
            expect(introductoryDiscount.price) == 0.0
            // Free trial should format as "0,00 lei" (zero uses "lei")
            expect(introductoryDiscount.localizedPriceString) == "0,00 lei"
        }

        // Test promotional discounts
        let discounts = unwrappedFirstProduct.discounts
        expect(discounts.count) >= 2

        // Find discounts by price to avoid order dependency
        let discount4099 = try XCTUnwrap(discounts.first { $0.price == 40.99 })
        expect(discount4099.localizedPriceString) == "40,99 lei"

        let discount2015 = try XCTUnwrap(discounts.first { $0.price == 20.15 })
        expect(discount2015.localizedPriceString) == "20,15 lei"
    }

    private func createSut(
        storeKitVersion: StoreKitVersion,
        storefront: any StorefrontType
    ) throws -> ProductsManagerType {
        mockSystemInfo = MockSystemInfo(
            platformInfo: Purchases.PlatformInfo(
                flavor: "xyz",
                version: "123"
            ),
            finishTransactions: true,
            storeKitVersion: storeKitVersion,
            preferredLocalesProvider: preferredLocalesProvider
        )
        mockSystemInfo.stubbedStorefront = storefront

        mockDeviceCache = MockDeviceCache(
            systemInfo: mockSystemInfo
        )
        mockBackend = MockBackend()

        mockOfferingsAPI = try XCTUnwrap(mockBackend.offerings as? MockOfferingsAPI)

        let productsManager = ProductsManagerFactory.createManager(
            apiKeyValidationResult: .validApplePlatform,
            diagnosticsTracker: nil,
            systemInfo: mockSystemInfo,
            backend: mockBackend,
            deviceCache: mockDeviceCache,
            requestTimeout: 60
        )

        self.offeringsManager = OfferingsManager(
            deviceCache: mockDeviceCache,
            operationDispatcher: mockOperationDispatcher,
            systemInfo: mockSystemInfo,
            backend: mockBackend,
            offeringsFactory: mockOfferingsFactory,
            productsManager: productsManager,
            diagnosticsTracker: nil
        )

        return productsManager
    }

    override func changeStorefront(_ new: String, file: FileString = #fileID, line: UInt = #line) async throws {
        // Update mockSystemInfo if it's already initialized, otherwise just change the test session storefront
        if let mockSystemInfo = mockSystemInfo {
            mockSystemInfo.stubbedStorefront = MockStorefront(countryCode: new)
        }
        try await super.changeStorefront(new, file: file, line: line)
    }
}
