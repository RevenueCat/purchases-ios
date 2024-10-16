//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CachingProductsManagerTests.swift
//
//  Created by Nacho Soto on 9/14/22.

import Nimble
@testable import RevenueCat
import XCTest

class CachingProductsManagerTests: TestCase {

    private var mockManager: MockProductsManager!
    private var mockDiagnosticsTracker: DiagnosticsTrackerType?
    private var cachingManager: CachingProductsManager!

    override func setUp() async throws {
        try await super.setUp()

        let systemInfo = MockSystemInfo(finishTransactions: false)

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.mockDiagnosticsTracker = MockDiagnosticsTracker()
        }

        self.mockManager = MockProductsManager(
            diagnosticsTracker: self.mockDiagnosticsTracker,
            systemInfo: systemInfo,
            requestTimeout: Configuration.storeKitRequestTimeoutDefault
        )
        self.cachingManager = CachingProductsManager(manager: self.mockManager)
    }

    func testFetchesNotCachedProduct() async throws {
        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        let result = try await self.cachingManager.products(withIdentifiers: [Self.productID])
        expect(result.onlyElement) === product

        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

    func testFetchesNotCachedProductsIfOneOfTheRequestedProductsIsNotCached() async throws {
        let product1 = self.createMockProduct(identifier: "product1")
        let product2 = self.createMockProduct(identifier: "product2")

        // Cache 1 product
        self.mockManager.stubbedProductsCompletionResult = .success([product1])
        _ = try await self.cachingManager.products(withIdentifiers: [product1.productIdentifier])

        // Request 2 products
        self.mockManager.stubbedProductsCompletionResult = .success([product1, product2])

        let result = try await self.cachingManager.products(withIdentifiers: [product1.productIdentifier,
                                                                              product2.productIdentifier])
        expect(result) == [product1, product2]

        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([product1.productIdentifier]), // First product fetched
            Set([product2.productIdentifier]) // Only second product fetched
        ]
    }

    func testRefetchesProductIfItFailedTheFirstTime() async throws {
        self.mockManager.stubbedProductsCompletionResult = .failure(ErrorUtils.productRequestTimedOutError())

        // This will fail
        let failedResult = try? await self.cachingManager.products(withIdentifiers: [Self.productID])
        expect(failedResult).to(beNil())

        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        let result = try await self.cachingManager.products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) === product
        self.expectProductsWereFetched(times: 2, for: Self.productID)
    }

    func testReturnsCachedProduct() async throws {
        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        _ = try await self.cachingManager.products(withIdentifiers: [Self.productID])
        let result = try await self.cachingManager.products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) === product
        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

    func testRefetchesAfterClearingCache() async throws {
        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        _ = try await self.cachingManager.products(withIdentifiers: [Self.productID])
        self.cachingManager.clearCache()

        let result = try await self.cachingManager.products(withIdentifiers: [Self.productID])

        expect(result.onlyElement) === product
        self.expectProductsWereFetched(times: 2, for: Self.productID)
    }

    func testReusesProductRequestsIfAlreadyInProgress() async throws {
        let product = self.createMockProduct()

        self.mockManager.productResultDelay = 0.01
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        var tasks: [Task<Set<StoreProduct>, Error>] = []

        for _ in 0..<5 {
            tasks.append(
                Task { [manager = self.cachingManager!] in
                    try await manager.products(withIdentifiers: [Self.productID])
                }
            )
        }

        for task in tasks {
            let result = try await task.value
            expect(result.onlyElement) === product
        }

        self.expectProductsWereFetched(times: 1, for: Self.productID)
    }

}

// MARK: - Private

private extension CachingProductsManagerTests {

    static let productID = "com.revenuecat.product_id"

    func expectProductsWereFetched(
        times: Int,
        for identifiers: String...,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(file: file, line: line, self.mockManager.invokedProductsCount)
            .to(equal(times), description: "Products fetched an unexpected number of times")
        expect(file: file, line: line, self.mockManager.invokedProductsParameters) == Set(identifiers)
    }

    func createMockProduct(identifier: String = CachingProductsManagerTests.productID) -> StoreProduct {
        // Using SK1 products because they can be mocked, but `CachingProductsManager
        // works with generic `StoreProduct`s regardless of what they contain
        return StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: identifier))
    }

}
