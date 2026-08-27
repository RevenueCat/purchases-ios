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

    // MARK: - virtualCurrencies() Tests
    func testVirtualCurrenciesAsyncForwardsSuccess() async throws {
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        let vcs = try await self.purchases.virtualCurrencies()
        expect(vcs).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.virtualCurrenciesCallCount).to(equal(1))
    }

    func testVirtualCurrenciesCallbackForwardsSuccess() async throws {
        self.setupPurchases()
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
        self.setupPurchases()
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
        self.setupPurchases()
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
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        await waitUntil { completed in
            self.purchases.getVirtualCurrencies { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }

    func testVirtualCurrenciesCallbackCallsErrorOnMainThread() async throws {
        self.setupPurchases()
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
        self.setupPurchases()
        self.purchases.invalidateVirtualCurrenciesCache()
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }

    // MARK: - cachedVirtualCurrencies Tests
    func testCachedVirtualCurrenciesReturnsCachedVirtualCurrencies() {
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedCachedVirtualCurrencies = Self.mockVirtualCurrencies

        let cachedVirtualCurrencies = self.purchases.cachedVirtualCurrencies
        expect(cachedVirtualCurrencies).to(equal(Self.mockVirtualCurrencies))
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }

    func testCachedVirtualCurrenciesReturnsNilWhenThereAreNoCachedVirtualCurrencies() {
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedCachedVirtualCurrencies = nil

        let cachedVirtualCurrencies = self.purchases.cachedVirtualCurrencies
        expect(cachedVirtualCurrencies).to(beNil())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCalled).to(beTrue())
        expect(self.mockVirtualCurrencyManager.cachedVirtualCurrenciesCallCount).to(equal(1))
        expect(Thread.isMainThread).to(beTrue())
    }

    // MARK: - spendVirtualCurrencies() Tests

    func testSpendVirtualCurrenciesThrowsUnsupportedErrorWhenIAMIsNotEnabled() async throws {
        self.setupPurchases()
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
        self.setupPurchases()
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

    // MARK: - spendVirtualCurrency(amounts:reference:completion:) Tests

    func testSpendVirtualCurrencyCallbackThrowsUnsupportedErrorWhenIAMIsNotEnabled() async throws {
        self.setupPurchases()
        await waitUntil { completed in
            self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil) { vcs, error in
                expect(vcs).to(beNil())
                expect(error).to(matchError(ErrorCode.unsupportedError))
                completed()
            }
        }

        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCalled).to(beFalse())
    }

    func testSpendVirtualCurrencyCallbackForwardsSuccessWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        await waitUntil { completed in
            self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: "ref-3") { vcs, error in
                expect(vcs).to(equal(Self.mockVirtualCurrencies))
                expect(error).to(beNil())
                completed()
            }
        }

        expect(self.mockVirtualCurrencyManager.spendVirtualCurrenciesCallCount).to(equal(1))
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.amounts)
            == ["GLD": 10]
        expect(self.mockVirtualCurrencyManager.invokedSpendVirtualCurrenciesParametersList.first?.reference)
            == "ref-3"
    }

    func testSpendVirtualCurrencyCallbackForwardsErrorWhenIAMIsEnabled() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        let backendError: BackendError = .networkError(.offlineConnection())
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .failure(backendError)

        await waitUntil { completed in
            self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil) { vcs, error in
                expect(vcs).to(beNil())
                expect(error).to(matchError(backendError.asPurchasesError))
                completed()
            }
        }
    }

    func testSpendVirtualCurrencyCallbackCallsSuccessOnMainThread() async throws {
        self.tokenManager = MockTokenManager(enabled: true)
        self.setupPurchases()
        self.mockVirtualCurrencyManager.stubbedSpendVirtualCurrenciesResult = .success(Self.mockVirtualCurrencies)

        await waitUntil { completed in
            self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil) { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }

    func testSpendVirtualCurrencyCallbackCallsErrorOnMainThread() async throws {
        self.setupPurchases()
        // `self.tokenManager` defaults to disabled, so this exercises the error path via the guard.
        await waitUntil { completed in
            self.purchases.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil) { _, _ in
                expect(Thread.isMainThread).to(beTrue())
                completed()
            }
        }
    }
}
