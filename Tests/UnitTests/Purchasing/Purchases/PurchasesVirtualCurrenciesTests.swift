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
class PurchasesVirtualCurrenciesTests: BasePurchasesTests {

    private nonisolated static let mockVirtualCurrencies = VirtualCurrencies(
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
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        let vcs = try await self.purchases.virtualCurrencies()
        expect(vcs).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesCallbackForwardsSuccess() async throws {
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        await waitUntil { completed in
            self.purchases.virtualCurrencies { vcs, error in
                expect(vcs).to(equal(Self.mockVirtualCurrencies))
                expect(error).to(beNil())
                completed()
            }
        }

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

        await waitUntil { completed in
            self.purchases.virtualCurrencies { vcs, error in
                expect(vcs).to(beNil())
                expect(error).to(matchError(backendError.asPurchasesError))
                completed()
            }
        }

        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesCallbackCallsSuccessOnMainThread() async throws {
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        await waitUntil { completed in
            self.purchases.virtualCurrencies { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }

    func testVirtualCurrenciesCallbackCallsErrorOnMainThread() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .failure(backendError)

        await waitUntil { completed in
            self.purchases.virtualCurrencies { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }

    // MARK: - invalidateVirtualCurrenciesCache() Tests
    func testInvalidateVirtualCurrenciesCacheCallsVirtualCurrencyManagerInvalidateVirtualCurrenciesCache() async {
        self.purchases.invalidateVirtualCurrenciesCache()
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }

    // MARK: - cachedVirtualCurrencies Tests
    func testCachedVirtualCurrenciesReturnsCachedVirtualCurrencies() {
        self.mockVirtualCurrencyManager.stubbedCachedVirtualCurrencies = Self.mockVirtualCurrencies

        let cachedVirtualCurrencies = self.purchases.cachedVirtualCurrencies
        expect(cachedVirtualCurrencies).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }

    func testCachedVirtualCurrenciesReturnsNilWhenThereAreNoCachedVirtualCurrencies() {
        self.mockVirtualCurrencyManager.stubbedCachedVirtualCurrencies = nil

        let cachedVirtualCurrencies = self.purchases.cachedVirtualCurrencies
        expect(cachedVirtualCurrencies).to(beNil())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }
}
