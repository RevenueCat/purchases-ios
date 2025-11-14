//
//  ProductsManagerFactoryTests.swift
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
class ProductsManagerFactoryTests: StoreKitConfigTestCase {

    var mockSystemInfo: MockSystemInfo!
    var mockDeviceCache: MockDeviceCache!
    var mockBackend: MockBackend!
    var mockOfferingsAPI: MockOfferingsAPI!
    let mockOfferingsFactory = MockOfferingsFactory()
    let mockOperationDispatcher = MockOperationDispatcher()
    var offeringsManager: OfferingsManager!
    let preferredLocalesProvider: PreferredLocalesProvider = .mock(locales: ["en_US"])

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSomething() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        testSession.locale = Locale(identifier: "ro_RO")
        let manager = try createSut(storeKitVersion: .storeKit2, storefront: MockStorefront(countryCode: "ro_RO"))

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
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:]),
                priceFormattingRuleSets: [
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
                ]
            )
        )

        mockOfferingsAPI.stubbedGetOfferingsCompletionResult = .success(offeringsResponse)

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
        XCTAssert(type(of: unwrappedFirstProduct.priceFormatter) == CurrencySymbolOverridingPriceFormatter.self)
        expect(unwrappedFirstProduct.priceFormatter?.string(from: NSNumber(integerLiteral: 1))) == "1,00 leu"
    }

    private func createSut(storeKitVersion: StoreKitVersion, storefront: any StorefrontType) throws -> ProductsManagerType {
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
        mockSystemInfo.stubbedStorefront = MockStorefront(countryCode: new)
        try await super.changeStorefront(new, file: file, line: line)
    }
}
