//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesVirtualCurrenciesTests.swift
//
//  Created by Will Taylor on 6/17/25.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@MainActor
class PurchasesVirtualCurrenciesTests: BasePurchasesTests, Sendable {

    private let mockVirtualCurrencies = VirtualCurrencies(
        virtualCurrencies: [
            "GLD": VirtualCurrency(balance: 100, name: "Gold", code: "GLD", serverDescription: "It's gold!"),
            "SLV": VirtualCurrency(balance: 200, name: "Silver", code: "SLV", serverDescription: "It's silver!")
        ]
    )

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    // MARK: - virtualCurrencies() Tests
    func testVirtualCurrenciesAsyncForwardsSuccess() async throws {
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(self.mockVirtualCurrencies)

        let vcs = try await self.purchases.virtualCurrencies()
        expect(vcs).to(equal(self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesCallbackForwardsSuccess() async throws {
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(self.mockVirtualCurrencies)

        let expectation = self.expectation(description: "Wait for virtualCurrencies callback")

        self.purchases.virtualCurrencies { vcs, error in
            expect(vcs).to(equal(self.mockVirtualCurrencies))
            expect(error).to(beNil())
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesAsyncForwardsError() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .failure(backendError)

        do {
            _ = try await self.purchases.virtualCurrencies()
            fail("An error should have been thrown")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesCallbackForwardsError() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .failure(backendError)

        let expectation = self.expectation(description: "Wait for virtualCurrencies callback")

        self.purchases.virtualCurrencies { vcs, error in
            expect(vcs).to(beNil())
            expect(error).to(matchError(backendError.asPurchasesError))
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    // MARK: - invalidateVirtualCurrenciesCache() Tests
    func testInvalidateVirtualCurrenciesCacheCallsVirtualCurrencyManagerInvalidateVirtualCurrenciesCache() async {
        await self.purchases.invalidateVirtualCurrenciesCache()
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount).to(equal(1))
    }
}
