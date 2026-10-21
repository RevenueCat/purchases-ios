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
//  Created by Nacho Soto on 7/26/23.

import Nimble
@_spi(Internal) @testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class CachingProductsManagerIntegrationTests: StoreKitConfigTestCase {

    func testFetchProductsWithIdentifiersSK1() throws {
        let manager = Self.createManager(.storeKit1)

        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchProductsWithIdentifiersSK2() throws {
        guard #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = Self.createManager(.storeKit2)

        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.store_product_request_received_response,
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchCachedSK1Products() throws {
        let manager = Self.createManager(.storeKit1)

        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK1StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.offering.products_already_cached(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testFetchCachedSK2Products() throws {
        guard #available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let manager = Self.createManager(.storeKit2)

        _ = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }
        let receivedProducts = waitUntilValue(timeout: Self.requestDispatchTimeout) { completed in
            manager.products(withIdentifiers: Set([Self.productID]), completion: completed)
        }

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        let product = try XCTUnwrap(unwrappedProducts.onlyElement).product

        expect(product).to(beAnInstanceOf(SK2StoreProduct.self))
        expect(product.productIdentifier) == Self.productID

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.store_product_request_received_response,
            level: .debug,
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.offering.products_already_cached(identifiers: [Self.productID]),
            level: .debug,
            expectedCount: 1
        )
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2ProductsReuseGeneralProductFetch() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let products = try await manager.products(withIdentifiers: [Self.productID])
        let sk2Products = try await manager.sk2Products(withIdentifiers: [Self.productID])

        let product = try XCTUnwrap(products.onlyElement)
        let sk2Product = try XCTUnwrap(sk2Products.onlyElement)
        expect(product.sk2Product) == sk2Product.underlyingSK2Product
        self.verifyStoreProductRequests(count: 1)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testGeneralProductsReuseSK2ProductFetch() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let sk2Products = try await manager.sk2Products(withIdentifiers: [Self.productID])
        let products = try await manager.products(withIdentifiers: [Self.productID])

        let product = try XCTUnwrap(products.onlyElement)
        let sk2Product = try XCTUnwrap(sk2Products.onlyElement)
        expect(product.sk2Product) == sk2Product.underlyingSK2Product
        self.verifyStoreProductRequests(count: 1)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testGeneralRequestSharesInFlightFetchWithSK2Request() async throws {
        try await self.verifyInFlightSharing(startWithSK2: false)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2RequestSharesInFlightFetchWithGeneralRequest() async throws {
        try await self.verifyInFlightSharing(startWithSK2: true)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCachedSK1ProductDoesNotSatisfySK2Request() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let sk1Product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: Self.productID))
        manager.cache(sk1Product)
        let sk2Products = try await manager.sk2Products(withIdentifiers: [Self.productID])
        let generalProducts = try await manager.products(withIdentifiers: [Self.productID])

        expect(sk2Products.onlyElement?.productIdentifier) == Self.productID
        expect(generalProducts.onlyElement) === sk1Product
        self.verifyStoreProductRequests(count: 1)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testExplicitlyCachedSK2ProductIsAvailableThroughBothAPIs() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let product = try await self.fetchSk2StoreProduct()
        let manager = Self.createManager(.storeKit2)
        manager.cache(product)
        let sk2Products = try await manager.sk2Products(withIdentifiers: [Self.productID])
        let generalProducts = try await manager.products(withIdentifiers: [Self.productID])

        expect(sk2Products.onlyElement) == product
        expect(generalProducts.onlyElement?.sk2Product) == product.underlyingSK2Product
        self.verifyStoreProductRequests(count: 0)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK1ConfigurationKeepsGeneralProductsSeparateFromSK2() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit1)
        let sk2Products = try await manager.sk2Products(withIdentifiers: [Self.productID])
        let generalProducts = try await manager.products(withIdentifiers: [Self.productID])

        expect(sk2Products.onlyElement?.productIdentifier) == Self.productID
        expect(generalProducts.onlyElement?.sk1Product).toNot(beNil())
        expect(generalProducts.onlyElement?.sk2Product).to(beNil())
        self.verifyStoreProductRequests(count: 2)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testClearingCacheInvalidatesBothProductAPIs() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        _ = try await manager.products(withIdentifiers: [Self.productID])
        _ = try await manager.sk2Products(withIdentifiers: [Self.productID])
        manager.clearCache()
        _ = try await manager.sk2Products(withIdentifiers: [Self.productID])
        _ = try await manager.products(withIdentifiers: [Self.productID])

        self.verifyStoreProductRequests(count: 2)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testPartialSK2CacheHitFetchesOnlyMissingProductsAcrossAPIs() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        _ = try await manager.sk2Products(withIdentifiers: [Self.productID])
        let products = try await manager.products(withIdentifiers: [Self.productID, "lifetime"])

        expect(Set(products.map(\.id))) == [Self.productID, "lifetime"]
        self.verifyStoreProductRequests(count: 2)
        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: ["lifetime"]),
            level: .debug,
            expectedCount: 1
        )
    }

    func testSharingSK2ProductsPreservesBillingPlanMetadata() async throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()
        guard #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, *) else { return }
        let manager = Self.createManager(.storeKit2)
        let baseID = Self.productIDWithBillingPlans
        let planID = "\(baseID):monthly"
        let products = try await manager.products(withIdentifiers: [baseID, planID])
        let sk2Products = try await manager.sk2Products(withIdentifiers: [baseID, planID])
        let plan = try XCTUnwrap(products.first { $0.id == planID })
        let cachedPlan = try XCTUnwrap(sk2Products.first { $0.id == planID })

        expect(Set(sk2Products.map(\.id))) == [baseID, planID]
        expect(plan.installmentsInfo).toNot(beNil())
        expect(cachedPlan.installmentsInfo) == plan.installmentsInfo
        expect(cachedPlan.introductoryDiscount) == plan.introductoryDiscount
        self.verifyStoreProductRequests(count: 1)
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension CachingProductsManagerIntegrationTests {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func verifyInFlightSharing(startWithSK2: Bool) async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let completed = self.expectation(description: "Both product APIs complete")
        completed.expectedFulfillmentCount = 2
        let completions = Atomic(0)
        let starts = Atomic(0)
        let joined = Atomic(false)
        let generalCompletion: ProductsManagerType.Completion = { result in
            expect(try? result.get().onlyElement?.id) == Self.productID
            completions.modify { $0 += 1 }
            completed.fulfill()
        }
        let sk2Completion: ProductsManagerType.SK2Completion = { result in
            expect(try? result.get().onlyElement?.id) == Self.productID
            completions.modify { $0 += 1 }
            completed.fulfill()
        }
        let startMessage = Strings.storeKit.no_cached_products_starting_store_products_request(
            identifiers: [Self.productID]
        ).description
        let joinMessage = Strings.offering.found_existing_product_request(identifiers: [Self.productID]).description
        let previousLogHandler = Logger.internalLogHandler
        defer { TestLogHandler.restore() }
        Logger.internalLogHandler = { level, message, category, file, function, line in
            previousLogHandler(level, message, category, file, function, line)
            if message.contains(joinMessage) { joined.value = true }
            guard message.contains(startMessage) else { return }
            let count = starts.modify { $0 += 1; return $0 }
            // General requests pass through the outer cache before reaching the shared SK2 cache.
            guard count == (startWithSK2 ? 1 : 2) else { return }
            // The cache registered this request, but its fetch has not started yet.
            if startWithSK2 {
                manager.products(withIdentifiers: [Self.productID], completion: generalCompletion)
            } else {
                manager.sk2Products(withIdentifiers: [Self.productID], completion: sk2Completion)
            }
            expect(joined.value) == true
            expect(completions.value) == 0
        }

        if startWithSK2 {
            manager.sk2Products(withIdentifiers: [Self.productID], completion: sk2Completion)
        } else {
            manager.products(withIdentifiers: [Self.productID], completion: generalCompletion)
        }
        await self.fulfillment(of: [completed], timeout: 5)
        expect(joined.value) == true
        self.verifyStoreProductRequests(count: 1)
    }

    func verifyStoreProductRequests(count: Int, file: FileString = #file, line: UInt = #line) {
        let message = Strings.storeKit.store_product_request_received_response
        if count == 0 {
            self.logger.verifyMessageWasNotLogged(message, file: file, line: line)
        } else {
            self.logger.verifyMessageWasLogged(message, expectedCount: count, file: file, line: line)
        }
    }

    static func createManager(_ storeKitVersion: StoreKitVersion) -> ProductsManagerType {
        return CachingProductsManager(
            manager:
                ProductsManager(
                    diagnosticsTracker: nil,
                    systemInfo: MockSystemInfo(
                        finishTransactions: true,
                        storeKitVersion: storeKitVersion
                    ),
                    requestTimeout: Self.requestTimeout
                )
        )
    }

}
