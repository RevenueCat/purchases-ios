//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStoreProductsManagerTests.swift
//
//  Created by Antonio Pallares on 28/7/25.

import Nimble
@testable import RevenueCat
import XCTest

#if SIMULATED_STORE

class SimulatedStoreProductsManagerTests: TestCase {

    static var requestTimeout: TimeInterval = 60

    private var deviceCache: MockDeviceCache!
    var backend: MockBackend!
    var webBilling: MockWebBillingAPI!

    override func setUp() async throws {
        try await super.setUp()

        // Avoid continuing with potentially bad data after a failed assertion
        self.continueAfterFailure = false

        self.deviceCache = .init()
        self.deviceCache.stubbedAppUserID = "appUserID"
        self.backend = MockBackend()
        self.webBilling = try XCTUnwrap(self.backend.webBilling as? MockWebBillingAPI)
    }

    func testFetchSimulatedStoreProductsWithIdentifiersTriggersTheCorrectRequest() async throws {
        self.webBilling.stubbedGetWebBillingProductsCompletionResult =
            .failure(BackendError.networkError(.offlineConnection()))

        let manager = self.createManager()
        await waitUntil { completed in
            manager.products(withIdentifiers: ["product1", "product2"]) { _ in
                completed()
            }
        }

        expect(self.webBilling.invokedGetWebBillingProducts).to(beTrue())
        expect(self.webBilling.invokedGetWebBillingProductsCount).to(equal(1))
        let params = try XCTUnwrap(self.webBilling.invokedGetWebBillingProductsParameters)
        expect(params.appUserID).to(equal("appUserID"))
        expect(params.productIds).to(equal(Set(["product1", "product2"])))
    }

    func testFetchSimulatedStoreProductsDoesNothingIfEmptyIdentifiers() async throws {
        let manager = self.createManager()
        await waitUntil { completed in
            manager.products(withIdentifiers: []) { _ in
                completed()
            }
        }

        expect(self.webBilling.invokedGetWebBillingProducts).to(beFalse())
    }

    func testFetchSimulatedStoreProductsWithSuccessfulResponseReturnsProducts() throws {
        self.webBilling.stubbedGetWebBillingProductsCompletionResult = .success(
            SimulatedStoreMockData.yearlyAndMonthlyWebBillingProductsResponse
        )
        let productIds: Set = [SimulatedStoreMockData.yearlyProduct.identifier,
                               SimulatedStoreMockData.monthlyProduct.identifier]

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

    func testFetchSimulatedStoreProductsWithBackendErrorPropagatesError() throws {
        let expectedError = BackendError.networkError(.serverDown())
        self.webBilling.stubbedGetWebBillingProductsCompletionResult = .failure(expectedError)

        let manager = self.createManager()
        let result = waitUntilValue { completed in
            manager.products(withIdentifiers: ["product1"]) { result in
                completed(result)
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(expectedError.asPurchasesError))
    }

    func testFetchSimulatedStoreProductsWithToStoreProductConversionErrorPropagatesError() throws {
        // This represents a scenario where the backend returns a response that cannot be converted to StoreProduct
        self.webBilling.stubbedGetWebBillingProductsCompletionResult = .success(
            SimulatedStoreMockData.noBasePricesWebBillingProductsResponse
        )
        let productId = SimulatedStoreMockData.productWithoutBasePrices.identifier

        let manager = self.createManager()
        let result = waitUntilValue { completed in
            manager.products(withIdentifiers: [productId]) { result in
                completed(result)
            }
        }

        expect(result).to(beFailure())
    }

    fileprivate func createManager() -> SimulatedStoreProductsManager {
        return SimulatedStoreProductsManager(backend: self.backend,
                                             deviceCache: self.deviceCache,
                                             requestTimeout: Self.requestTimeout)
    }
}

#endif // SIMULATED_STORE
