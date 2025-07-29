//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreProductsManagerTests.swift
//
//  Created by Antonio Pallares on 28/7/25.

import Nimble
@testable import RevenueCat
import XCTest

#if TEST_STORE

class TestStoreProductsManagerTests: TestCase {

    static var requestTimeout: TimeInterval = 60

    private var deviceCache: MockDeviceCache!
    var backend: MockBackend!
    var offerings: MockOfferingsAPI!

    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        self.deviceCache = .init()
        self.deviceCache.stubbedAppUserID = "appUserID"
        self.backend = MockBackend()
        self.offerings = try XCTUnwrap(self.backend.offerings as? MockOfferingsAPI)
    }

    func testFetchTestStoreProductsWithIdentifiersTriggersTheCorrectRequest() async throws {
        self.offerings.stubbedGetWebBillingProductsCompletionResult =
            .failure(BackendError.networkError(.offlineConnection()))

        let manager = self.createManager()
        await waitUntil { completed in
            manager.products(withIdentifiers: ["product1", "product2"]) { _ in
                completed()
            }
        }

        expect(self.offerings.invokedGetWebBillingProducts).to(beTrue())
        expect(self.offerings.invokedGetWebBillingProductsCount).to(equal(1))
        let params = try XCTUnwrap(self.offerings.invokedGetWebBillingProductsParameters)
        expect(params.appUserID).to(equal("appUserID"))
        expect(params.productIds).to(equal(Set(["product1", "product2"])))
    }

    func testFetchTestStoreProductsDoesNothingIfEmptyIdentifiers() async throws {
        let manager = self.createManager()
        await waitUntil { completed in
            manager.products(withIdentifiers: []) { _ in
                completed()
            }
        }

        expect(self.offerings.invokedGetWebBillingProducts).to(beFalse())
    }

    func testFetchTestStoreProductsWithSuccessfulResponseReturnsProducts() throws {
        self.offerings.stubbedGetWebBillingProductsCompletionResult = .success(
            TestStoreMockData.yearlyAndMonthlyWebBillingProductsResponse
        )
        let productIds: Set = [TestStoreMockData.yearlyProduct.identifier,
                               TestStoreMockData.monthlyProduct.identifier]

        let manager = self.createManager()
        let result = waitUntilValue { completed in
            manager.products(withIdentifiers: productIds) { result in
                completed(result)
            }
        }

        expect(result).to(beSuccess())
        let products = try XCTUnwrap(result?.value)
        expect(products.count) == 2
        let productIdentifiers = Set(products.map(\.productIdentifier))
        expect(productIdentifiers).to(equal(productIds))
    }

    func testFetchTestStoreProductsWithBackendErrorPropagatesError() throws {
        let expectedError = BackendError.networkError(.serverDown())
        self.offerings.stubbedGetWebBillingProductsCompletionResult = .failure(expectedError)

        let manager = self.createManager()
        let result = waitUntilValue { completed in
            manager.products(withIdentifiers: ["product1"]) { result in
                completed(result)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(expectedError.asPurchasesError))
    }

    func testFetchTestStoreProductsWithToStoreProductConversionErrorPropagatesError() throws {
        // This represents a scenario where the backend returns a response that cannot be converted to StoreProduct
        self.offerings.stubbedGetWebBillingProductsCompletionResult = .success(
            TestStoreMockData.noBasePricesWebBillingProductsResponse
        )
        let productId = TestStoreMockData.productWithoutBasePrices.identifier

        let manager = self.createManager()
        let result = waitUntilValue { completed in
            manager.products(withIdentifiers: [productId]) { result in
                completed(result)
            }
        }

        expect(result).to(beFailure())
    }

    fileprivate func createManager() -> TestStoreProductsManager {
        return TestStoreProductsManager(backend: self.backend,
                                        deviceCache: self.deviceCache,
                                        requestTimeout: Self.requestTimeout)
    }
}

#endif // TEST_STORE
