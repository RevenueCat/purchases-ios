//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyManagerTests.swift
//
//  Created by Will Taylor on 6/4/25.

@_spi(Internal) @testable import RevenueCat
import XCTest

class VirtualCurrencyManagerTests: TestCase {

    private var mockIdentityManager: MockIdentityManager!
    private var mockDeviceCache: MockDeviceCache!
    private var mockSystemInfo: MockSystemInfo!
    private var mockBackend: MockBackend!
    private var mockVirtualCurrenciesAPI: MockVirtualCurrenciesAPI!
    private var virtualCurrencyManager: VirtualCurrencyManager!

    private var mockVirtualCurrencies: VirtualCurrencies!
    private var mockVirtualCurrenciesResponse: VirtualCurrenciesResponse!
    private var mockVirtualCurrenciesData: Data!

    private let appUserID = "appUserID"

    override func setUp() async throws {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: true)
        self.mockDeviceCache = MockDeviceCache()
        self.mockBackend = MockBackend()
        // swiftlint:disable:next force_cast
        self.mockVirtualCurrenciesAPI = (self.mockBackend.virtualCurrenciesAPI as! MockVirtualCurrenciesAPI)
        self.mockIdentityManager = MockIdentityManager(
            mockAppUserID: appUserID,
            mockDeviceCache: mockDeviceCache
        )

        self.mockVirtualCurrencies = VirtualCurrencies(
            virtualCurrencies: [
                "GLD": VirtualCurrency(balance: 100, name: "Gold", code: "GLD", serverDescription: "It's gold!"),
                "SLV": VirtualCurrency(balance: 200, name: "Silver", code: "SLV", serverDescription: "It's silver!")
            ]
        )

        self.mockVirtualCurrenciesResponse = VirtualCurrenciesResponse(
            virtualCurrencies: [
                "GLD_FROM_NETWORK": .init(
                    balance: 100,
                    name: "Gold",
                    code: "GLD_FROM_NETWORK",
                    description: "It's gold!"
                ),
                "SLV_FROM_NETWORK": .init(
                    balance: 200,
                    name: "Silver",
                    code: "SLV_FROM_NETWORK",
                    description: "It's silver!"
                )
            ]
        )
        self.mockVirtualCurrenciesData = try JSONEncoder().encode(self.mockVirtualCurrencies)

        self.virtualCurrencyManager = VirtualCurrencyManager(
            identityManager: self.mockIdentityManager,
            deviceCache: self.mockDeviceCache,
            backend: self.mockBackend,
            systemInfo: self.mockSystemInfo

        )
    }

    // MARK: - virtualCurrencies() Cache Tests
    func testVirtualCurrenciesReturnsCachedVirtualCurrenciesWhenCacheIsNotStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies()
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
                where: {$0 == (self.appUserID, false)}
            )
        )
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            virtualCurrencies,
            self.mockVirtualCurrencies,
            "Returned virtual currencies should equal the cached virtual currencies"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
    }

    func testVirtualCurrenciesReturnsNetworkVirtualCurrenciesWhenCacheIsStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = true
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies()

        // Ensure that we checked to see if the cache was stale
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
                where: {$0 == (self.appUserID, false)}
            )
        )

        // Ensure that we didn't load VCs from the cache
        XCTAssertFalse(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should not be called when the cache is stale"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            0,
            "cachedVirtualCurrenciesData should not be called when the cache is stale"
        )

        // Check that the virtual currencies API was called
        XCTAssertTrue(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrencies,
            "getVirtualCurrencies should be called when the cache is stale"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            1,
            "getVirtualCurrencies should be called exactly once when the cache is stale"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesParameters!.appUserId,
            self.appUserID,
            "The correct appUserID should be passed to getVirtualCurrencies"
        )
        XCTAssertFalse(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesParameters!.isAppBackgrounded,
            "The correct isAppBackgrounded should be passed to getVirtualCurrencies"
        )

        // Check that the virtual currencies returned are the ones from the network
        XCTAssertEqual(
            virtualCurrencies,
            expectVirtualCurrencies,
            "Returned virtual currencies should equal the virtual currencies from the network"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.virtual_currencies_stale_updating_from_network,
            level: .debug
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
    }

    func testVirtualCurrenciesReturnsNetworkVirtualCurrenciesWhenCacheIsEmpty() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies()

        // Ensure that we checked to see if the cache was stale
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once when the cache is empty"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
                where: {$0 == (self.appUserID, false)}
            )
        )

        // Ensure that we tried to load VCs from the cache (it's empty though)
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called once when the cache is empty"
        )

        // Check that the virtual currencies API was called
        XCTAssertTrue(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrencies,
            "getVirtualCurrencies should be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            1,
            "getVirtualCurrencies should be called exactly once when the cache is empty"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesParameters!.appUserId,
            self.appUserID,
            "The correct appUserID should be passed to getVirtualCurrencies"
        )
        XCTAssertFalse(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesParameters!.isAppBackgrounded,
            "The correct isAppBackgrounded should be passed to getVirtualCurrencies"
        )

        // Check that the virtual currencies returned are the ones from the network
        XCTAssertEqual(
            virtualCurrencies,
            expectVirtualCurrencies,
            "Returned virtual currencies should equal the virtual currencies from the network"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.no_cached_virtual_currencies,
            level: .debug
        )
        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
    }

    func testCachesVirtualCurrenciesFetchedFromNetwork() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectedVirtualCurrenciesToBeCached = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)

        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies()

        XCTAssertEqual(virtualCurrencies, expectedVirtualCurrenciesToBeCached)
        XCTAssertFalse(
            self.mockDeviceCache.isVirtualCurrenciesCacheStale(appUserID: self.appUserID, isAppBackgrounded: false)
        )
        XCTAssertTrue(self.mockDeviceCache.invokedCacheVirtualCurrencies)
        XCTAssertEqual(self.mockDeviceCache.invokedCacheVirtualCurrenciesCount, 1)

        // Comparing the Datas themselves was flaky on macOS, giving errors like
        // XCTAssertEqual failed: ("229 bytes") is not equal to ("229 bytes")
        // Instead we'll decode the cached data to a VirtualCurrencies object, which we
        // can compare reliably.
        let cachedVirtualCurrenciesData = self.mockDeviceCache.invokedCacheVirtualCurrenciesParametersList[0].0
        let cachedVirtualCurrencies = try JSONDecoder().decode(
            VirtualCurrencies.self,
            from: cachedVirtualCurrenciesData
        )
        XCTAssertEqual(cachedVirtualCurrencies, expectedVirtualCurrenciesToBeCached)
        XCTAssertEqual(
            self.mockDeviceCache.invokedCacheVirtualCurrenciesParametersList[0].1, self.appUserID
        )
    }

    func testParsingCorruptedCachedVirtualCurrenciesDataFetchesFromNetwork() async throws {
        let corruptedData = "{};thisIsCorruptedData%^&*#@(".data(using: .utf8)!

        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = corruptedData
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let virtualCurrencies = try await self.virtualCurrencyManager.virtualCurrencies()
        let expectedVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        XCTAssertEqual(virtualCurrencies, expectedVirtualCurrencies)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
    }

    // MARK: - cachedVirtualCurrencies Tests
    func testCachedVirtualCurrenciesReturnsNilVirtualCurrenciesWhenCacheIsEmpty() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = true

        let virtualCurrencies: VirtualCurrencies? = virtualCurrencyManager.cachedVirtualCurrencies()

        // Ensure that we did not check to see if the cache was stale
        XCTAssertFalse(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            0,
            "cachedVirtualCurrenciesData should not be called when the cache is empty"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 0)

        // Ensure that we tried to load VCs from the cache (it's empty though)
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called once when the cache is empty"
        )

        // Check that the virtual currencies API was not called
        XCTAssertFalse(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrencies,
            "getVirtualCurrencies should not be called when the cache is empty"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            0,
            "getVirtualCurrencies should not be called when the cache is empty"
        )

        // Check that the virtual currencies returned are the ones from the network
        XCTAssertNil(
            virtualCurrencies,
            "Returned virtual currencies should be nil"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.no_cached_virtual_currencies,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
    }

    func testCachedVirtualCurrenciesReturnsCachedVirtualCurrenciesWhenCacheIsNotStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies: VirtualCurrencies? = virtualCurrencyManager.cachedVirtualCurrencies()
        XCTAssertFalse(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should not be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            0,
            "cachedVirtualCurrenciesData should not be called"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 0)
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            virtualCurrencies,
            self.mockVirtualCurrencies,
            "Returned virtual currencies should equal the cached virtual currencies"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
    }

    func testCachedVirtualCurrenciesReturnsCachedVirtualCurrenciesWhenCacheIsStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = true

        let virtualCurrencies: VirtualCurrencies? = virtualCurrencyManager.cachedVirtualCurrencies()
        XCTAssertFalse(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should not be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            0,
            "cachedVirtualCurrenciesData should not be called"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 0)
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called"
        )
        XCTAssertEqual(
            virtualCurrencies,
            self.mockVirtualCurrencies,
            "Returned virtual currencies should equal the cached virtual currencies"
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.vending_from_cache,
            level: .debug
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.virtual_currencies_updated_from_network,
            level: .debug
        )
    }

    // MARK: - invalidateVirtualCurrenciesCache() Tests
    func testInvalidateVirtualCurrenciesCacheCallsClearVirtualCurrenciesCache() async {
        virtualCurrencyManager.invalidateVirtualCurrenciesCache()

        XCTAssertTrue(self.mockDeviceCache.invokedClearVirtualCurrenciesCache)
        XCTAssertEqual(self.mockDeviceCache.invokedClearVirtualCurrenciesCacheCount, 1)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalidating_virtual_currencies_cache,
            level: .debug
        )
    }

    // MARK: - Network Error Handling Tests
    func testVirtualCurrenciesProperlyHandlesNetworkErrors() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .failure(
            .networkError(NetworkError.serverDown())
        )

        do {
            _ = try await virtualCurrencyManager.virtualCurrencies()

            XCTFail("An error should have been thrown when the network call failed.")
        } catch {
            let purchasesError = try XCTUnwrap(error as? PurchasesError)
            XCTAssertEqual(purchasesError.error, ErrorCode.unknownBackendError)
            self.logger.verifyMessageWasLogged(
                Strings.virtualCurrencies.no_cached_virtual_currencies,
                level: .debug
            )
            self.logger.verifyMessageWasLogged(
                Strings.virtualCurrencies.virtual_currencies_updated_from_network_error(error),
                level: .error
            )
        }
    }

    // MARK: - spendVirtualCurrencies() Tests

    func testSpendVirtualCurrenciesSendsResolvedAmountsToBackendAndReturnsResult() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let virtualCurrencies = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": 50],
            reference: "order-123"
        )

        XCTAssertTrue(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies)
        XCTAssertEqual(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesCount, 1)
        XCTAssertEqual(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts, ["GLD": 50])
        XCTAssertEqual(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.reference, "order-123")

        let expectedVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        XCTAssertEqual(virtualCurrencies, expectedVirtualCurrencies)
    }

    func testSpendVirtualCurrenciesFiltersOutZeroAmountsAndFetchesInsteadOfSpending() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": 0],
            reference: nil
        )

        XCTAssertFalse(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies,
            "spendVirtualCurrencies should not call the backend when all amounts resolve to zero"
        )
        XCTAssertEqual(virtualCurrencies, self.mockVirtualCurrencies)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("GLD", 0),
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.empty_spend_amount,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesWithEmptyAmountsDictionaryFallsBackToFetchingVirtualCurrencies() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: [:],
            reference: nil
        )

        XCTAssertFalse(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies)
        XCTAssertEqual(virtualCurrencies, self.mockVirtualCurrencies)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.empty_spend_amount,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesFiltersOutNegativeAmountsAndLogsWarning() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": -50, "SLV": 20],
            reference: nil
        )

        // The negative amount should be dropped entirely rather than being sent as a positive amount.
        XCTAssertEqual(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts, ["SLV": 20])

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("GLD", -50),
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesWithOnlyNegativeAmountFallsBackToFetchingVirtualCurrencies() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": -50],
            reference: nil
        )

        XCTAssertFalse(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies)
        XCTAssertEqual(virtualCurrencies, self.mockVirtualCurrencies)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("GLD", -50),
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.empty_spend_amount,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesFiltersOutZeroAndNegativeAmountsKeepingOnlyPositiveAmounts() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": 100, "SLV": 0, "PLT": -30],
            reference: nil
        )

        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts,
            ["GLD": 100]
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("SLV", 0),
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("PLT", -30),
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesFiltersOutCodesLongerThanTheLengthLimitAndLogsWarning() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let tooLongCode = String(repeating: "A", count: 101)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: [tooLongCode: 10, "GLD": 25],
            reference: nil
        )

        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts,
            ["GLD": 25]
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_code,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesAllowsCodesExactlyAtTheLengthLimit() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let maxLengthCode = String(repeating: "A", count: 100)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: [maxLengthCode: 10],
            reference: nil
        )

        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts,
            [maxLengthCode: 10]
        )

        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.invalid_code,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesFiltersOutInvalidCodesAndInvalidAmountsIndependently() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let tooLongCode = String(repeating: "A", count: 101)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: [tooLongCode: 10, "GLD": -5, "SLV": 100],
            reference: nil
        )

        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts,
            ["SLV": 100]
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_code,
            level: .warn
        )
        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.invalid_spend_amount("GLD", -5),
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesFallsBackToFetchingWhenTooManyCodesAreResolved() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let manyAmounts = Dictionary(uniqueKeysWithValues: (0..<1000).map { ("CODE\($0)", 1) })

        let virtualCurrencies = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: manyAmounts,
            reference: nil
        )

        XCTAssertFalse(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies,
            "spendVirtualCurrencies should not call the backend when too many codes are resolved"
        )
        XCTAssertEqual(virtualCurrencies, self.mockVirtualCurrencies)

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.too_many_codes,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesSpendsWhenResolvedCountIsJustUnderTheCodeLimit() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let manyAmounts = Dictionary(uniqueKeysWithValues: (0..<999).map { ("CODE\($0)", 1) })

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: manyAmounts,
            reference: nil
        )

        XCTAssertTrue(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrencies)
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.amounts.count,
            999
        )

        self.logger.verifyMessageWasNotLogged(
            Strings.virtualCurrencies.too_many_codes,
            level: .warn
        )
    }

    func testSpendVirtualCurrenciesPassesReferenceThrough() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": 10],
            reference: "reference-456"
        )

        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.reference,
            "reference-456"
        )
    }

    func testSpendVirtualCurrenciesPassesNilReferenceThrough() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(
            amounts: ["GLD": 10],
            reference: nil
        )

        XCTAssertNil(self.mockVirtualCurrenciesAPI.invokedSpendVirtualCurrenciesParameters?.reference)
    }

    func testSpendVirtualCurrenciesCachesResultOnSuccess() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectedVirtualCurrenciesToBeCached = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)

        _ = try await virtualCurrencyManager.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil)

        XCTAssertTrue(self.mockDeviceCache.invokedCacheVirtualCurrencies)
        XCTAssertEqual(self.mockDeviceCache.invokedCacheVirtualCurrenciesCount, 1)

        let cachedVirtualCurrenciesData = self.mockDeviceCache.invokedCacheVirtualCurrenciesParametersList[0].0
        let cachedVirtualCurrencies = try JSONDecoder().decode(
            VirtualCurrencies.self,
            from: cachedVirtualCurrenciesData
        )
        XCTAssertEqual(cachedVirtualCurrencies, expectedVirtualCurrenciesToBeCached)
        XCTAssertEqual(
            self.mockDeviceCache.invokedCacheVirtualCurrenciesParametersList[0].1, self.appUserID
        )

        self.logger.verifyMessageWasLogged(
            Strings.virtualCurrencies.virtual_currencies_spent_on_network,
            level: .debug
        )
    }

    func testSpendVirtualCurrenciesPropagatesNetworkErrorsAndDoesNotCache() async throws {
        self.mockVirtualCurrenciesAPI.stubbedSpendVirtualCurrenciesResult = .failure(
            .networkError(NetworkError.serverDown())
        )

        do {
            _ = try await virtualCurrencyManager.spendVirtualCurrencies(amounts: ["GLD": 10], reference: nil)

            XCTFail("An error should have been thrown when the network call failed.")
        } catch {
            let purchasesError = try XCTUnwrap(error as? PurchasesError)
            XCTAssertEqual(purchasesError.error, ErrorCode.unknownBackendError)

            XCTAssertFalse(self.mockDeviceCache.invokedCacheVirtualCurrencies)

            self.logger.verifyMessageWasLogged(
                Strings.virtualCurrencies.virtual_currencies_spent_on_network_error(error),
                level: .error
            )
        }
    }
}
