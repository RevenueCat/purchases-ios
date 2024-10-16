//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2CachingProductsManagerTests.swift
//
//  Created by Nacho Soto on 9/14/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

/// Addition to `CachingProductsManagerTests` but for SK2 requests
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2CachingProductsManagerTests: StoreKitConfigTestCase {

    private var mockManager: MockProductsManager!
    private var cachingManager: CachingProductsManager!

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let systemInfo = MockSystemInfo(finishTransactions: false)

        self.mockManager = MockProductsManager(
            diagnosticsTracker: nil,
            systemInfo: systemInfo,
            requestTimeout: Configuration.storeKitRequestTimeoutDefault
        )
        self.cachingManager = CachingProductsManager(manager: self.mockManager)
    }

    func testFetchesNotCachedProduct() async throws {
        let product = try await self.fetchSk2StoreProduct()
        self.mockManager.stubbedSk2StoreProductsResult = .success([product])

        let result = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])
        expect(result.onlyElement) == product

        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

    func testFetchesNotCachedProductIfOneOfTheRequestedProductsIsNotCached() async throws {
        let product1 = try await self.fetchSk2StoreProduct()
        let product2 = try await self.fetchSk2StoreProduct("lifetime")

        // Cache 1 product
        self.mockManager.stubbedSk2StoreProductsResult = .success([product1])
        _ = try await self.cachingManager.sk2Products(withIdentifiers: [product1.productIdentifier])

        // Request 2 products
        self.mockManager.stubbedSk2StoreProductsResult = .success([product1, product2])

        let result = try await self.cachingManager.sk2Products(withIdentifiers: [product1.productIdentifier,
                                                                                 product2.productIdentifier])
        expect(result) == [product1, product2]

        expect(self.mockManager.invokedSk2StoreProductsCount) == 2
        expect(self.mockManager.invokedSk2StoreProductsParameterList) == [
            Set([product1.productIdentifier]), // First product fetched
            Set([product2.productIdentifier]) // Second product fetched
        ]
    }

    func testRefetchesProductIfItFailedTheFirstTime() async throws {
        self.mockManager.stubbedSk2StoreProductsResult = .failure(ErrorUtils.productRequestTimedOutError())

        // This will fail
        let failedResult = try? await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])
        expect(failedResult).to(beNil())

        let product = try await self.fetchSk2StoreProduct()
        self.mockManager.stubbedSk2StoreProductsResult = .success([product])

        let result = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) == product
        self.expectProductsWereFetched(times: 2, for: Self.productID)
    }

    func testReturnsCachedProduct() async throws {
        let product = try await self.fetchSk2StoreProduct()
        self.mockManager.stubbedSk2StoreProductsResult = .success([product])

        _ = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])
        let result = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) == product
        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

    func testRefetchesAfterClearingCache() async throws {
        let product = try await self.fetchSk2StoreProduct()
        self.mockManager.stubbedSk2StoreProductsResult = .success([product])

        _ = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])
        self.cachingManager.clearCache()

        let result = try await self.cachingManager.sk2Products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) == product
        self.expectProductsWereFetched(times: 2, for: Self.productID)
    }

    func testReusesProductRequestsIfAlreadyInProgress() async throws {
        let product = try await self.fetchSk2StoreProduct()

        self.mockManager.productResultDelay = 0.01
        self.mockManager.stubbedSk2StoreProductsResult = .success([product])

        var tasks: [Task<Set<SK2StoreProduct>, Error>] = []

        for _ in 0..<5 {
            tasks.append(Task { [manager = self.cachingManager!] in
                try await manager.sk2Products(withIdentifiers: [Self.productID])
            })
        }

        for task in tasks {
            let result = try await task.value
            expect(result.onlyElement) == product
        }

        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension StoreKit2CachingProductsManagerTests {

    func expectProductsWereFetched(
        times: Int,
        for identifiers: String...,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(file: file, line: line, self.mockManager.invokedSk2StoreProductsCount)
            .to(equal(times), description: "Products fetched an unexpected number of times")
        expect(file: file, line: line, self.mockManager.invokedSk2StoreProductsParameter) == Set(identifiers)
    }

}
