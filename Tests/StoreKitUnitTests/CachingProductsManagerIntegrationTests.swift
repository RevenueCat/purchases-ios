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

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testEligibilityReusesGeneralProductFetch() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let checker = self.createEligibilityChecker(manager: manager)
        _ = try await manager.products(withIdentifiers: [Self.productID])

        let eligibility = try await checker.sk2CheckEligibility([Self.productID])

        expect(eligibility[Self.productID]?.status) == .eligible
        self.verifyStoreProductRequests(count: 1)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testGeneralProductsReuseEligibilityProductFetch() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let checker = self.createEligibilityChecker(manager: manager)
        _ = try await checker.sk2CheckEligibility([Self.productID])

        let products = try await manager.products(withIdentifiers: [Self.productID])

        expect(products.onlyElement?.sk2Product).toNot(beNil())
        self.verifyStoreProductRequests(count: 1)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testGeneralRequestSharesInFlightFetchWithEligibility() async throws {
        try await self.verifyInFlightSharing(startWithEligibility: false)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testEligibilitySharesInFlightFetchWithGeneralRequest() async throws {
        try await self.verifyInFlightSharing(startWithEligibility: true)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testUnexpectedSK1ProductDoesNotProduceSK2Eligibility() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let sk1Product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: Self.productID))
        manager.cache(sk1Product)
        let checker = self.createEligibilityChecker(manager: manager)

        let eligibility = try await checker.sk2CheckEligibility([Self.productID])

        expect(eligibility[Self.productID]?.status) == .unknown
        self.verifyStoreProductRequests(count: 0)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testExplicitlyCachedSK2ProductIsAvailableToEligibility() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let product = try await self.fetchSk2StoreProduct()
        let manager = Self.createManager(.storeKit2)
        manager.cache(product)
        let checker = self.createEligibilityChecker(manager: manager)

        let eligibility = try await checker.sk2CheckEligibility([Self.productID])
        let generalProducts = try await manager.products(withIdentifiers: [Self.productID])

        expect(eligibility[Self.productID]?.status) == .eligible
        expect(generalProducts.onlyElement?.sk2Product) == product.underlyingSK2Product
        self.verifyStoreProductRequests(count: 0)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testClearingCacheInvalidatesProductsUsedByEligibility() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let checker = self.createEligibilityChecker(manager: manager)
        _ = try await manager.products(withIdentifiers: [Self.productID])
        _ = try await checker.sk2CheckEligibility([Self.productID])
        manager.clearCache()
        _ = try await checker.sk2CheckEligibility([Self.productID])
        _ = try await manager.products(withIdentifiers: [Self.productID])

        self.verifyStoreProductRequests(count: 2)
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testEligibilityFetchesOnlyProductsMissingFromCache() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let manager = Self.createManager(.storeKit2)
        let checker = self.createEligibilityChecker(manager: manager)
        _ = try await manager.products(withIdentifiers: [Self.productID])

        let eligibility = try await checker.sk2CheckEligibility([Self.productID, "lifetime"])

        expect(eligibility[Self.productID]?.status) == .eligible
        expect(eligibility["lifetime"]?.status) == .noIntroOfferExists
        self.verifyStoreProductRequests(count: 2)
        self.logger.verifyMessageWasLogged(
            Strings.storeKit.no_cached_products_starting_store_products_request(identifiers: ["lifetime"]),
            level: .debug,
            expectedCount: 1
        )
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testSharedFetchFailureReachesEligibilityAndProductsAndCanBeRetried() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let product = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let fetcher = self.createDeferredFetcher(result: .failure(ErrorUtils.productRequestTimedOutError()))
        let manager = CachingProductsManager(manager: fetcher)
        let checker = self.createEligibilityChecker(manager: manager)
        var generalResult: Result<Set<StoreProduct>, PurchasesError>?
        manager.products(withIdentifiers: [Self.productID]) { generalResult = $0 }
        let task = Task { try await checker.sk2CheckEligibility([Self.productID]) }
        defer { task.cancel() }
        try await self.waitForSharedRequest()

        fetcher.completeDeferredProductsRequest(at: 0)
        let eligibilityResult = await task.result
        expect(generalResult).to(beFailure())
        expect(eligibilityResult).to(beFailure())
        expect(fetcher.invokedProductsCount) == 1

        fetcher.stubbedProductsCompletionResult = .success([product])
        fetcher.shouldDeferProductsCompletion = false
        let eligibility = try await checker.sk2CheckEligibility([Self.productID])
        let products = try await manager.products(withIdentifiers: [Self.productID])
        expect(eligibility[Self.productID]?.status) == .eligible
        expect(products.onlyElement) === product
        expect(fetcher.invokedProductsCount) == 2
    }

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testLateEligibilityProductResponseDoesNotRepopulateClearedCache() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let sk2Product = try await self.fetchSk2Product()
        let oldProduct = StoreProduct(sk2Product: sk2Product)
        let newProduct = StoreProduct(sk2Product: sk2Product)
        let fetcher = self.createDeferredFetcher(result: .success([oldProduct]))
        let manager = CachingProductsManager(manager: fetcher)
        let checker = self.createEligibilityChecker(manager: manager)
        let task = Task { try await checker.sk2CheckEligibility([Self.productID]) }
        defer { task.cancel() }
        try await asyncWait(description: "Eligibility product response was not captured", timeout: .seconds(5)) {
            fetcher.deferredProductsRequestCount == 1
        }

        manager.clearCache()
        fetcher.stubbedProductsCompletionResult = .success([newProduct])
        var newResult: Result<Set<StoreProduct>, PurchasesError>?
        manager.products(withIdentifiers: [Self.productID]) { newResult = $0 }
        expect(fetcher.invokedProductsCount) == 2
        fetcher.completeDeferredProductsRequest(at: 1)
        fetcher.completeDeferredProductsRequest(at: 0)

        let eligibility = try await task.value
        expect(eligibility[Self.productID]?.status) == .eligible
        expect(try newResult?.get().onlyElement) === newProduct
        let cached = try await manager.products(withIdentifiers: [Self.productID])
        expect(cached.onlyElement) === newProduct
        expect(fetcher.invokedProductsCount) == 2
    }

    func testSharingProductsPreservesBillingPlanMetadataForEligibility() async throws {
        try AvailabilityChecks.iOS264APIAvailableOrSkipTest()
        guard #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, *) else { return }
        let manager = Self.createManager(.storeKit2)
        let baseID = Self.productIDWithBillingPlans
        let planID = "\(baseID):monthly"
        let products = try await manager.products(withIdentifiers: [baseID, planID])
        let plan = try XCTUnwrap(products.first { $0.id == planID })
        let checker = self.createEligibilityChecker(manager: manager)

        let eligibility = try await checker.sk2CheckEligibility([baseID, planID])
        let cachedProducts = try await manager.products(withIdentifiers: [baseID, planID])
        let cachedPlan = try XCTUnwrap(cachedProducts.first { $0.id == planID })

        expect(Set(eligibility.keys)) == [baseID, planID]
        expect(eligibility.values.map(\.status)).toNot(contain(IntroEligibilityStatus.unknown))
        expect(cachedPlan) === plan
        expect(cachedPlan.installmentsInfo).toNot(beNil())
        self.verifyStoreProductRequests(count: 1)
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension CachingProductsManagerIntegrationTests {

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func verifyInFlightSharing(startWithEligibility: Bool) async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let product = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let fetcher = self.createDeferredFetcher(result: .success([product]))
        let manager = CachingProductsManager(manager: fetcher)
        let checker = self.createEligibilityChecker(manager: manager)
        var generalResult: Result<Set<StoreProduct>, PurchasesError>?

        if !startWithEligibility {
            manager.products(withIdentifiers: [Self.productID]) { generalResult = $0 }
        }
        let eligibilityTask = Task { try await checker.sk2CheckEligibility([Self.productID]) }
        defer { eligibilityTask.cancel() }
        try await asyncWait(description: "Product response was not captured", timeout: .seconds(5)) {
            fetcher.deferredProductsRequestCount == 1
        }
        if startWithEligibility {
            manager.products(withIdentifiers: [Self.productID]) { generalResult = $0 }
        }
        try await self.waitForSharedRequest()

        expect(generalResult).to(beNil())
        expect(fetcher.invokedProductsCount) == 1
        fetcher.completeDeferredProductsRequest(at: 0)

        let eligibility = try await eligibilityTask.value
        expect(try generalResult?.get().onlyElement) === product
        expect(eligibility[Self.productID]?.status) == .eligible
        expect(fetcher.invokedProductsCount) == 1
    }

    func createDeferredFetcher(result: Result<Set<StoreProduct>, PurchasesError>) -> MockProductsManager {
        let fetcher = MockProductsManager(
            diagnosticsTracker: nil,
            systemInfo: MockSystemInfo(finishTransactions: true, storeKitVersion: .storeKit2),
            requestTimeout: Self.requestTimeout
        )
        fetcher.stubbedProductsCompletionResult = result
        fetcher.shouldDeferProductsCompletion = true
        return fetcher
    }

    func waitForSharedRequest() async throws {
        let message = Strings.offering.found_existing_product_request(identifiers: [Self.productID]).description
        try await asyncWait(description: "Eligibility and products did not share their request", timeout: .seconds(5)) {
            self.logger.messages.contains { $0.message.contains(message) }
        }
    }

    func createEligibilityChecker(manager: ProductsManagerType) -> TrialOrIntroPriceEligibilityChecker {
        let systemInfo = MockSystemInfo(finishTransactions: true, storeKitVersion: .storeKit2)
        return TrialOrIntroPriceEligibilityChecker(
            systemInfo: systemInfo,
            receiptFetcher: MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: systemInfo),
            introEligibilityCalculator: MockIntroEligibilityCalculator(productsManager: manager,
                                                                       receiptParser: MockReceiptParser()),
            backend: MockBackend(),
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: "app_user"),
            operationDispatcher: MockOperationDispatcher(),
            productsManager: manager,
            diagnosticsTracker: nil
        )
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
