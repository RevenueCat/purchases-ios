//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerTests.swift
//
//  Created by Andrés Boedo on 7/23/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class ProductsManagerTests: StoreKitConfigTestCase {

    func testFetchProductsWithIdentifiersSK1() throws {
        let manager = self.createManager(storeKitVersion: .storeKit1)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([identifier]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())

        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    func testFetchProductsWithIdentifiersSK2() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = self.createManager(storeKitVersion: .storeKit2)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([identifier]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())

        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == identifier
    }

    func testClearCacheAfterStorefrontChangesSK1() async throws {
        let manager = self.createManager(storeKitVersion: .storeKit1)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        var unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "USD"

        testSession.locale = Locale(identifier: "es_ES")
        try await changeStorefront("ESP")

        // Note: this test passes only because the method `clearCache`
        // is manually executed. `ProductsManager` does not detect Storefront changes to invalidate the
        // cache. The changes are now managed by `StoreKit2StorefrontListenerDelegate`.
        manager.clearCache()

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "EUR"
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testInvalidateAndReFetchCachedProductsAfterStorefrontChangesSK2() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let manager = self.createManager(storeKitVersion: .storeKit2)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var receivedProducts: Set<StoreProduct>?

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        var unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "USD"

        testSession.locale = Locale(identifier: "es_ES")
        try await changeStorefront("ESP")

        // Note: this test passes only because the method `clearCache`
        // is manually executed. `ProductsManager` does not detect Storefront changes to invalidate the
        // cache. The changes are now managed by `StoreKit2StorefrontListenerDelegate`.
        manager.clearCache()

        receivedProducts = try await manager.products(withIdentifiers: Set([identifier]))

        expect(receivedProducts).notTo(beNil())
        unwrappedFirstProduct = try XCTUnwrap(receivedProducts?.first)
        expect(unwrappedFirstProduct.currencyCode) == "EUR"
    }

    fileprivate func createManager(storeKitVersion: StoreKitVersion,
                                   diagnosticsTracker: DiagnosticsTrackerType? = nil) -> ProductsManager {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        return ProductsManager(
            diagnosticsTracker: diagnosticsTracker,
            systemInfo: MockSystemInfo(
                platformInfo: platformInfo,
                finishTransactions: true,
                storeKitVersion: storeKitVersion
            ),
            requestTimeout: Self.requestTimeout
        )
    }

}

// swiftlint:disable type_name
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class SK1ProductsManagerDiagnosticsTrackingTests: ProductsManagerTests {

    private var mockDiagnosticsTracker: MockDiagnosticsTracker!

    private var productsManager: ProductsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.mockDiagnosticsTracker = MockDiagnosticsTracker()
    }

    func testFetchProductsWithIdentifiersSK1TracksCorrectly() throws {
        let manager = self.createManager(storeKitVersion: .storeKit1,
                                         diagnosticsTracker: self.mockDiagnosticsTracker)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([identifier]), completion: completed)
        }

        expect(self.mockDiagnosticsTracker.trackedProductsRequestParams.value).toEventually(haveCount(1))
        let params = self.mockDiagnosticsTracker.trackedProductsRequestParams.value.first
        expect(params?.wasSuccessful) == true
        expect(params?.storeKitVersion) == .storeKit1
        expect(params?.errorMessage).to(beNil())
        expect(params?.errorCode).to(beNil())
    }

}
// swiftlint:enable type_name

// swiftlint:disable type_name
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class SK2ProductsManagerDiagnosticsTrackingTests: ProductsManagerTests {

    private var mockDiagnosticsTracker: MockDiagnosticsTracker!

    private var productsManager: ProductsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.mockDiagnosticsTracker = MockDiagnosticsTracker()
    }

    func testFetchProductsWithIdentifiersSK2TracksCorrectly() throws {
        let manager = self.createManager(storeKitVersion: .storeKit2,
                                         diagnosticsTracker: self.mockDiagnosticsTracker)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([identifier]), completion: completed)
        }

        expect(self.mockDiagnosticsTracker.trackedProductsRequestParams.value).toEventually(haveCount(1))
        let params = self.mockDiagnosticsTracker.trackedProductsRequestParams.value.first
        expect(params?.wasSuccessful) == true
        expect(params?.storeKitVersion) == .storeKit2
        expect(params?.errorMessage).to(beNil())
        expect(params?.errorCode).to(beNil())
    }

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0, *)
    func testFetchProductsWithIdentifiersSK2ErrorTracksCorrectly() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.unknown), forAPI: .loadProducts)
        let manager = self.createManager(storeKitVersion: .storeKit2,
                                         diagnosticsTracker: self.mockDiagnosticsTracker)

        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        _ = try? await manager.products(withIdentifiers: Set([identifier]))

        try await asyncWait(
            description: "Diagnostics tracker should have been called",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100)
        ) { [diagnosticsTracker = self.mockDiagnosticsTracker!] in
            diagnosticsTracker.trackedProductsRequestParams.value.count == 1
        }
        let params = self.mockDiagnosticsTracker.trackedProductsRequestParams.value.first
        expect(params?.wasSuccessful) == false
        expect(params?.storeKitVersion) == .storeKit2
        expect(params?.errorMessage) == "Products request error: Unable to Complete Request"
        expect(params?.errorCode) == 2
    }
    #endif

}
// swiftlint:enable type_name
