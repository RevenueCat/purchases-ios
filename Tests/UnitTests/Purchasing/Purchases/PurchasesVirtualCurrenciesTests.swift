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

@_spi(Internal) @testable import RevenueCat

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
            self.purchases.getVirtualCurrencies { vcs, error in
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
            self.purchases.getVirtualCurrencies { vcs, error in
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
            self.purchases.getVirtualCurrencies { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }

    func testVirtualCurrenciesCallbackCallsErrorOnMainThread() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .failure(backendError)

        await waitUntil { completed in
            self.purchases.getVirtualCurrencies { _, _ in
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

    // MARK: - spendVirtualCurrencies() Tests

    func testSpendVirtualCurrenciesThrowsUnsupportedErrorWhenIAMIsNotEnabled() async throws {
        // `self.tokenManager` defaults to disabled in `BasePurchasesTests.setUpWithError()`.
        var thrown: Error?
        do {
            _ = try await self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil)
        } catch {
            thrown = error
        }

        expect(thrown).to(matchError(ErrorCode.unsupportedError))
        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCalled).to(beFalse())
    }

    func testSpendVirtualCurrencyThrowsUnsupportedErrorWhenIAMIsNotEnabled() async throws {
        var thrown: Error?
        do {
            _ = try await self.purchases.spendVirtualCurrency(code: "GLD", amount: 10, reference: nil)
        } catch {
            thrown = error
        }

        expect(thrown).to(matchError(ErrorCode.unsupportedError))
        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCalled).to(beFalse())
    }

    func testSpendVirtualCurrenciesForwardsSuccessWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        let vcs = try await self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: "ref-1")

        expect(vcs).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCallCount).to(equal(1))
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.amounts)
            == ["GLD": 10]
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.reference)
            == "ref-1"
    }

    func testSpendVirtualCurrenciesForwardsErrorWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .failure(backendError)

        do {
            _ = try await self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil)
            fail("An error should have been thrown")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
    }

    func testSpendVirtualCurrencyConvenienceMethodForwardsSingleAmountWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        let vcs = try await self.purchases.spendVirtualCurrency(code: "GLD", amount: 25, reference: "ref-2")

        expect(vcs).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCallCount).to(equal(1))
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.amounts)
            == ["GLD": 25]
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.reference)
            == "ref-2"
    }

    func testSpendVirtualCurrencyConvenienceMethodForwardsErrorWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .failure(backendError)

        do {
            _ = try await self.purchases.spendVirtualCurrency(code: "GLD", amount: 25, reference: nil)
            fail("An error should have been thrown")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
    }
}
