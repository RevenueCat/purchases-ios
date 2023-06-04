//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsManagerStoreKitTests.swift
//
//  Created by Juanpe Catalán on 28/6/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class OfferingsManagerStoreKitTests: StoreKitConfigTestCase {

    var mockDeviceCache: MockDeviceCache!
    let mockOperationDispatcher = MockOperationDispatcher()
    let mockSystemInfo = MockSystemInfo(platformInfo: .init(flavor: "iOS", version: "3.2.1"),
                                        finishTransactions: true,
                                        storeKit2Setting: .enabledForCompatibleDevices)
    let mockBackend = MockBackend()
    var mockOfferings: MockOfferingsAPI!
    let mockOfferingsFactory = OfferingsFactory()
    var mockProductsManager: MockProductsManager!
    var offeringsManager: OfferingsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mockOfferings = try XCTUnwrap(self.mockBackend.offerings as? MockOfferingsAPI)
        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.mockSystemInfo)
        self.mockProductsManager = MockProductsManager(systemInfo: self.mockSystemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.offeringsManager = OfferingsManager(deviceCache: self.mockDeviceCache,
                                                 operationDispatcher: self.mockOperationDispatcher,
                                                 systemInfo: self.mockSystemInfo,
                                                 backend: self.mockBackend,
                                                 offeringsFactory: self.mockOfferingsFactory,
                                                 productsManager: self.mockProductsManager)
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
extension OfferingsManagerStoreKitTests {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testInvalidateAndReFetchCachedOfferingsAfterStorefrontChanges() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        mockOfferings.stubbedGetOfferingsCompletionResult = .success(MockData.anyBackendOfferingsResponse)
        var fetchedStoreProduct = try await fetchSk2StoreProduct()
        var storeProduct = StoreProduct(sk2Product: fetchedStoreProduct.underlyingSK2Product)
        mockProductsManager.stubbedProductsCompletionResult = .success(Set([storeProduct]))

        var receivedOfferings = try await offeringsManager.offerings(appUserID: MockData.anyAppUserID)
        var receivedProduct = try XCTUnwrap(receivedOfferings.current?.availablePackages.first?.storeProduct)
        expect(receivedProduct.currencyCode) == "USD"

        try self.changeLocale(identifier: "es_ES")
        try await changeStorefront("ESP")

        fetchedStoreProduct = try await fetchSk2StoreProduct()
        storeProduct = StoreProduct(sk2Product: fetchedStoreProduct.underlyingSK2Product)
        mockProductsManager.stubbedProductsCompletionResult = .success(Set([storeProduct]))

        // Note: this test passes only because the method `invalidateAndReFetchCachedOfferingsIfAppropiate`
        // is manually executed. `OfferingsManager` does not detect Storefront changes to invalidate the
        // cache. The changes are now managed by `StoreKit2StorefrontListenerDelegate`.
        offeringsManager.invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: MockData.anyAppUserID)

        receivedOfferings = try await offeringsManager.offerings(appUserID: MockData.anyAppUserID)
        receivedProduct = try XCTUnwrap(receivedOfferings.current?.availablePackages.first?.storeProduct)
        expect(receivedProduct.currencyCode) == "EUR"
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension OfferingsManagerStoreKitTests {

    enum MockData {
        static let anyAppUserID = ""

        static let anyBackendOfferingsResponse: OfferingsResponse = .init(
            currentOfferingId: "base",
            offerings: [
                .init(identifier: "base",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_monthly", platformProductIdentifier: StoreKitConfigTestCase.productID)
                      ])
            ]
        )
    }

}

private extension OfferingsManager {

    @available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
    func offerings(appUserID: String) async throws -> Offerings {
        return try await Async.call { completion in
            self.offerings(appUserID: appUserID, completion: completion)
        }
    }

}
