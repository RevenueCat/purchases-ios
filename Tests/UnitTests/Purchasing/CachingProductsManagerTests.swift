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

    func testReturnsBaseAndInstallmentProductsWithSameProductIdentifierUsingStoreProductID() async throws {
        let baseProduct = self.createTestProduct(
            productIdentifier: "com.revenuecat.product_id",
            installmentsInfo: nil
        )
        let installmentProduct = self.createTestProduct(
            productIdentifier: baseProduct.productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )

        self.mockManager.stubbedProductsCompletionResult = .success([baseProduct])
        _ = try await self.cachingManager.products(withIdentifiers: [baseProduct.id])

        self.mockManager.stubbedProductsCompletionResult = .success([installmentProduct])
        let result = try await self.cachingManager.products(withIdentifiers: [baseProduct.id, installmentProduct.id])

        expect(result) == [baseProduct, installmentProduct]
        expect(Set(result.map(\.productIdentifier))) == Set([baseProduct.productIdentifier])
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([baseProduct.id]),
            Set([installmentProduct.id])
        ]
    }

    func testDoesntReturnBaseProductWhenOnlyMonthlyProductIsCached() async throws {
        let productIdentifier = "com.revenuecat.product_id"
        let monthlyCommitmentProduct = self.createTestProduct(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )
        self.mockManager.stubbedProductsCompletionResult = .success([monthlyCommitmentProduct])

        // Cache the monthly plan using its compound StoreProduct ID: "com.revenuecat.product_id:monthly".
        _ = try await self.cachingManager.products(withIdentifiers: [monthlyCommitmentProduct.id])

        // Requesting the base product ID should not return the cached monthly plan.
        // It should be treated as a cache miss and fetched separately.
        self.mockManager.stubbedProductsCompletionResult = .success([])
        let result = try await self.cachingManager.products(withIdentifiers: [productIdentifier])

        expect(result.isEmpty) == true
        // Verify the base product request was sent to the underlying manager instead of being served from cache.
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([monthlyCommitmentProduct.id]),
            Set([productIdentifier])
        ]
    }

    func testDoesntReturnMonthlyProductWhenOnlyBaseProductIsCached() async throws {
        let productIdentifier = "com.revenuecat.product_id"
        let baseProduct = self.createTestProduct(
            productIdentifier: productIdentifier,
            installmentsInfo: nil
        )
        let monthlyCommitmentProduct = self.createTestProduct(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )

        self.mockManager.stubbedProductsCompletionResult = .success([baseProduct])

        // Cache the base product using its StoreProduct ID: "com.revenuecat.product_id".
        _ = try await self.cachingManager.products(withIdentifiers: [baseProduct.id])

        // Requesting the monthly compound ID should not return the cached base product.
        // It should be treated as a cache miss and fetched separately.
        self.mockManager.stubbedProductsCompletionResult = .success([])
        let result = try await self.cachingManager.products(withIdentifiers: [monthlyCommitmentProduct.id])

        expect(result.isEmpty) == true
        // Verify the monthly product request was sent to the underlying manager instead of being served from cache.
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([baseProduct.id]),
            Set([monthlyCommitmentProduct.id])
        ]
    }

    func testReturnsMonthlyCachedProductAndFetchesBaseProduct() async throws {
        let productIdentifier = "com.revenuecat.product_id"
        let baseProduct = self.createTestProduct(
            productIdentifier: productIdentifier,
            installmentsInfo: nil
        )
        let monthlyCommitmentProduct = self.createTestProduct(
            productIdentifier: productIdentifier,
            installmentsInfo: Self.installmentsInfo(billingPlanType: .monthly)
        )

        self.mockManager.stubbedProductsCompletionResult = .success([monthlyCommitmentProduct])

        // Cache the monthly plan using its compound StoreProduct ID: "com.revenuecat.product_id:monthly".
        _ = try await self.cachingManager.products(withIdentifiers: [monthlyCommitmentProduct.id])

        // Requesting the base and monthly IDs together should reuse the cached monthly product
        // and fetch only the missing base product.
        self.mockManager.stubbedProductsCompletionResult = .success([baseProduct])
        let result = try await self.cachingManager.products(withIdentifiers: [
            baseProduct.id,
            monthlyCommitmentProduct.id
        ])

        expect(result) == [baseProduct, monthlyCommitmentProduct]

        // Verify only the missing base product request was sent to the underlying manager.
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedProductsParametersList) == [
            Set([monthlyCommitmentProduct.id]),
            Set([baseProduct.id])
        ]
    }

    func testFetchesUncachedProductsByStoreProductID() async throws {
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

    func testSubsetSharesInFlightRequestAndOnlyReceivesRequestedProducts() throws {
        let first = self.createMockProduct(identifier: "first")
        let second = self.createMockProduct(identifier: "second")
        self.mockManager.stubbedProductsCompletionResult = .success([first, second])
        self.mockManager.shouldDeferProductsCompletion = true
        var allProducts: Result<Set<StoreProduct>, PurchasesError>?
        var subset: Result<Set<StoreProduct>, PurchasesError>?

        self.cachingManager.products(withIdentifiers: [first.id, second.id]) { allProducts = $0 }
        self.cachingManager.products(withIdentifiers: [second.id]) { subset = $0 }
        expect(self.mockManager.invokedProductsCount) == 1

        self.mockManager.completeDeferredProductsRequest(at: 0)
        expect(try allProducts?.get()) == [first, second]
        expect(try subset?.get()) == [second]
    }

    func testEmptyPlanAliasSharesCanonicalRequestAndCache() throws {
        let product = self.createMockProduct()
        let alias = "\(product.id):"
        self.mockManager.stubbedProductsCompletionResult = .success([product])
        self.mockManager.shouldDeferProductsCompletion = true
        var aliasResult: Result<Set<StoreProduct>, PurchasesError>?
        var canonicalResult: Result<Set<StoreProduct>, PurchasesError>?

        self.cachingManager.products(withIdentifiers: [alias]) { aliasResult = $0 }
        self.cachingManager.products(withIdentifiers: [product.id]) { canonicalResult = $0 }
        expect(self.mockManager.invokedProductsCount) == 1
        expect(self.mockManager.invokedProductsParameters) == [product.id]

        self.mockManager.completeDeferredProductsRequest(at: 0)
        expect(try aliasResult?.get()) == [product]
        expect(try canonicalResult?.get()) == [product]

        var cached: Result<Set<StoreProduct>, PurchasesError>?
        self.cachingManager.products(withIdentifiers: [alias, product.id]) { cached = $0 }
        expect(try cached?.get()) == [product]
        expect(self.mockManager.invokedProductsCount) == 1
    }

    func testInvalidIdentifiersReachFetcherUnchangedWithoutCacheWarnings() async throws {
        let identifiers: Set<String> = ["", ":monthly", "product::", "product:monthly:extra"]
        self.mockManager.stubbedProductsCompletionResult = .success([])
        self.logger.clearMessages()

        let products = try await self.cachingManager.products(withIdentifiers: identifiers)

        expect(products).to(beEmpty())
        expect(self.mockManager.invokedProductsParameters) == identifiers
        expect(self.logger.messages.filter { $0.level == .warn }).to(beEmpty())
    }

    func testSharedRequestPreservesEachCallersCachedProducts() throws {
        let firstCached = self.createMockProduct(identifier: "first-cached")
        let secondCached = self.createMockProduct(identifier: "second-cached")
        let fetched = self.createMockProduct(identifier: "fetched")
        self.cachingManager.cache(firstCached)
        self.cachingManager.cache(secondCached)
        self.mockManager.stubbedProductsCompletionResult = .success([fetched])
        self.mockManager.shouldDeferProductsCompletion = true
        var firstResult: Result<Set<StoreProduct>, PurchasesError>?
        var secondResult: Result<Set<StoreProduct>, PurchasesError>?

        self.cachingManager.products(withIdentifiers: [firstCached.id, fetched.id]) { firstResult = $0 }
        self.cachingManager.products(withIdentifiers: [secondCached.id, fetched.id]) { secondResult = $0 }
        self.mockManager.completeDeferredProductsRequest(at: 0)

        expect(self.mockManager.invokedProductsCount) == 1
        expect(try firstResult?.get()) == [firstCached, fetched]
        expect(try secondResult?.get()) == [secondCached, fetched]
    }

    func testRequestDuringUnderlyingInvalidationDoesNotRestoreStaleProducts() throws {
        let oldProduct = self.createMockProduct()
        let newProduct = self.createMockProduct()
        self.cachingManager.cache(oldProduct)
        self.mockManager.stubbedProductsCompletionResult = .success([oldProduct])
        var interleaved: Result<Set<StoreProduct>, PurchasesError>?
        self.mockManager.clearCacheHandler = {
            self.cachingManager.products(withIdentifiers: [Self.productID]) { interleaved = $0 }
            self.mockManager.stubbedProductsCompletionResult = .success([newProduct])
        }
        defer { self.mockManager.clearCacheHandler = nil }

        self.cachingManager.clearCache()
        expect(try interleaved?.get().onlyElement) === oldProduct

        var afterClear: Result<Set<StoreProduct>, PurchasesError>?
        self.cachingManager.products(withIdentifiers: [Self.productID]) { afterClear = $0 }
        expect(try afterClear?.get().onlyElement) === newProduct
    }

    func testClearCacheKeepsOldCallersButStartsNewRequest() throws {
        try self.verifyClearingCacheDuringRequest(completeOldRequestFirst: true)
    }

    func testOldResponseDoesNotOverwriteProductsFetchedAfterClearingCache() throws {
        try self.verifyClearingCacheDuringRequest(completeOldRequestFirst: false)
    }

    func testFailedSharedRequestCompletesAllCallersAndCanBeRetried() throws {
        self.mockManager.shouldDeferProductsCompletion = true
        self.mockManager.stubbedProductsCompletionResult = .failure(ErrorUtils.productRequestTimedOutError())
        var failures = 0
        for _ in 0..<2 {
            self.cachingManager.products(withIdentifiers: [Self.productID]) { result in
                if case .failure = result { failures += 1 }
            }
        }
        self.mockManager.completeDeferredProductsRequest(at: 0)
        expect(failures) == 2
        expect(self.mockManager.invokedProductsCount) == 1

        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])
        var retried: Result<Set<StoreProduct>, PurchasesError>?
        self.cachingManager.products(withIdentifiers: [Self.productID]) { retried = $0 }
        self.mockManager.completeDeferredProductsRequest(at: 1)
        expect(try retried?.get().onlyElement) === product
        expect(self.mockManager.invokedProductsCount) == 2
    }

    func testMissingProductsAreNotNegativelyCached() throws {
        self.mockManager.stubbedProductsCompletionResult = .success([])
        self.cachingManager.products(withIdentifiers: [Self.productID]) { _ in }
        let product = self.createMockProduct()
        self.mockManager.stubbedProductsCompletionResult = .success([product])
        var result: Result<Set<StoreProduct>, PurchasesError>?
        self.cachingManager.products(withIdentifiers: [Self.productID]) { result = $0 }

        expect(try result?.get().onlyElement) === product
        expect(self.mockManager.invokedProductsCount) == 2
    }

}

// MARK: - Private

private extension CachingProductsManagerTests {

    func verifyClearingCacheDuringRequest(completeOldRequestFirst: Bool) throws {
        let oldProduct = self.createMockProduct()
        let newProduct = self.createMockProduct()
        self.mockManager.shouldDeferProductsCompletion = true
        self.mockManager.stubbedProductsCompletionResult = .success([oldProduct])
        var oldResult: Result<Set<StoreProduct>, PurchasesError>?
        var newResult: Result<Set<StoreProduct>, PurchasesError>?

        self.cachingManager.products(withIdentifiers: [Self.productID]) { oldResult = $0 }
        self.cachingManager.clearCache()
        self.mockManager.stubbedProductsCompletionResult = .success([newProduct])
        self.cachingManager.products(withIdentifiers: [Self.productID]) { newResult = $0 }
        expect(self.mockManager.invokedProductsCount) == 2
        expect(self.mockManager.invokedClearCacheCount) == 1

        for index in completeOldRequestFirst ? [0, 1] : [1, 0] {
            self.mockManager.completeDeferredProductsRequest(at: index)
        }
        expect(try oldResult?.get().onlyElement) === oldProduct
        expect(try newResult?.get().onlyElement) === newProduct

        var cached: Result<Set<StoreProduct>, PurchasesError>?
        self.cachingManager.products(withIdentifiers: [Self.productID]) { cached = $0 }
        expect(try cached?.get().onlyElement) === newProduct
        expect(self.mockManager.invokedProductsCount) == 2
    }

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
