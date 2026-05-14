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

    func testReturnsCachedProductUsingStoreProductID() async throws {
        try AvailabilityChecks.iOS26APIAvailableOrSkipTest()

        let product = self.createTestProduct(
            productIdentifier: "com.revenuecat.product_id",
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )
        self.mockManager.stubbedProductsCompletionResult = .success([product])

        _ = try await self.cachingManager.products(withIdentifiers: [product.id])
        let result = try await self.cachingManager.products(withIdentifiers: [product.id])

        expect(result.onlyElement) === product
        self.expectProductsWereFetched(times: 1, for: product.id)
    }

    func testFetchesUncachedProductsByStoreProductID() async throws {
        try AvailabilityChecks.iOS26APIAvailableOrSkipTest()

        let cachedProduct = self.createTestProduct(
            productIdentifier: "com.revenuecat.product_id",
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )
        let uncachedProduct = self.createTestProduct(
            productIdentifier: "com.revenuecat.lifetime",
            installmentsInfo: nil
        )

        self.mockManager.stubbedProductsCompletionResult = .success([cachedProduct])
        _ = try await self.cachingManager.products(withIdentifiers: [cachedProduct.id])

        self.mockManager.stubbedProductsCompletionResult = .success([uncachedProduct])
        let result = try await self.cachingManager.products(withIdentifiers: [cachedProduct.id, uncachedProduct.id])

        expect(result) == [cachedProduct, uncachedProduct]
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([cachedProduct.id]),
            Set([uncachedProduct.id])
        ]
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

    static func installmentsInfo(
        billingPlanType: BillingPlanType
    ) -> InstallmentsInfo {
        return InstallmentsInfo(
            commitmentInstallmentsCount: 3,
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
            installmentBillingPrice: 3.99,
            installmentBillingDisplayPrice: "$3.99",
            commitmentTotalPeriod: SubscriptionPeriod(value: 3, unit: .month),
            commitmentTotalPrice: 11.97,
            commitmentTotalDisplayPrice: "$11.97",
            billingPlanType: billingPlanType
        )
    }

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

    func createTestProduct(
        productIdentifier: String = CachingProductsManagerTests.productID,
        installmentsInfo: InstallmentsInfo?
    ) -> StoreProduct {
        return TestStoreProduct(
            localizedTitle: "product",
            price: 11.97,
            currencyCode: "USD",
            localizedPriceString: "$11.97",
            productIdentifier: productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "description",
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            locale: Locale(identifier: "en_US"),
            installmentsInfo: installmentsInfo
        ).toStoreProduct()
    }

}
