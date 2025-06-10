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

@testable import RevenueCat
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
    func testVirtualCurrenciesWithForceRefreshTrueDoesntCheckCachedVirtualCurrencies() async throws {
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let _: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(forceRefresh: true)

        XCTAssertFalse(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should not be called when forceTry is true"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            0,
            "cachedVirtualCurrenciesData should not be called when forceTry is true"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            1,
            "virtual currencies should be fetched from the API when forceTry is true"
        )
    }

    func testVirtualCurrenciesWithForceRefreshFalseReturnsCachedVirtualCurrenciesWhenCacheIsNotStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false

        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(
            forceRefresh: false
        )
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called when forceTry is false"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once when forceTry is false"
        )
        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
                where: {$0 == (self.appUserID, false)}
            )
        )
        XCTAssertTrue(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
            "cachedVirtualCurrenciesData should be called when forceTry is false"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called when forceTry is false"
        )
        XCTAssertEqual(
            virtualCurrencies,
            self.mockVirtualCurrencies,
            "Returned virtual currencies should equal the cached virtual currencies"
        )
    }

    func testVirtualCurrenciesWithForceRefreshFalseReturnsNetworkVirtualCurrenciesWhenCacheIsStale() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = true
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(
            forceRefresh: false
        )

        // Ensure that we checked to see if the cache was stale
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called when forceTry is false and the cache is stale"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once when forceTry is false and the cache is stale"
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
            "cachedVirtualCurrenciesData should not be called when forceTry is false and the cache is stale"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            0,
            "cachedVirtualCurrenciesData should not be called when forceTry is false and the cache is stale"
        )

        // Check that the virtual currencies API was called
        XCTAssertTrue(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrencies,
            "getVirtualCurrencies should be called when forceRefresh is false and the cache is stale"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            1,
            "getVirtualCurrencies should be called exactly once when forceRefresh is false and the cache is stale"
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
    }

    func testVirtualCurrenciesWithForceRefreshFalseReturnsNetworkVirtualCurrenciesWhenCacheIsEmpty() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .success(self.mockVirtualCurrenciesResponse)

        let expectVirtualCurrencies = VirtualCurrencies(from: self.mockVirtualCurrenciesResponse)
        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(
            forceRefresh: false
        )

        // Ensure that we checked to see if the cache was stale
        XCTAssertTrue(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
            "isVirtualCurrenciesCacheStale should be called when forceTry is false and the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
            1,
            "cachedVirtualCurrenciesData should be called once when forceTry is false and the cache is empty"
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
            "cachedVirtualCurrenciesData should be called when forceTry is false and the cache is empty"
        )
        XCTAssertEqual(
            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
            1,
            "cachedVirtualCurrenciesData should be called once when forceTry is false and the cache is empty"
        )

        // Check that the virtual currencies API was called
        XCTAssertTrue(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrencies,
            "getVirtualCurrencies should be called when forceRefresh is false and the cache is empty"
        )
        XCTAssertEqual(
            self.mockVirtualCurrenciesAPI.invokedGetVirtualCurrenciesCount,
            1,
            "getVirtualCurrencies should be called exactly once when forceRefresh is false and the cache is empty"
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
    }

    // MARK: - Network Error Handling Tests
    func testVirtualCurrenciesProperlyHandlesNetworkErrors() async throws {
        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = nil
        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
        self.mockVirtualCurrenciesAPI.stubbedGetVirtualCurrenciesResult = .failure(
            .networkError(NetworkError.serverDown())
        )

        do {
            _ = try await virtualCurrencyManager.virtualCurrencies(
                forceRefresh: true
            )

            XCTFail("An error should have been thrown when the network call failed.")
        } catch {
            let purchasesError = try XCTUnwrap(error as? PurchasesError)
            XCTAssertEqual(purchasesError.error, ErrorCode.unknownBackendError)
        }
    }
}
