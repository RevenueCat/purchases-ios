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
    private var virtualCurrencyManager: VirtualCurrencyManager!

    private var mockVirtualCurrencies: VirtualCurrencies!
    private var mockVirtualCurrenciesData: Data!

    private let appUserID = "appUserID"

    override func setUp() async throws {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: true)
        self.mockDeviceCache = MockDeviceCache()
        self.mockIdentityManager = MockIdentityManager(
            mockAppUserID: appUserID,
            mockDeviceCache: mockDeviceCache
        )

        self.mockVirtualCurrencies = VirtualCurrencies(
            virtualCurrencies: [
                "GLD": VirtualCurrency(balance: 100),
                "SLV": VirtualCurrency(balance: 200)
            ]
        )
        self.mockVirtualCurrenciesData = try JSONEncoder().encode(self.mockVirtualCurrencies)

        self.virtualCurrencyManager = VirtualCurrencyManager(
            identityManager: self.mockIdentityManager,
            deviceCache: self.mockDeviceCache,
            systemInfo: self.mockSystemInfo

        )
    }

    // MARK: - virtualCurrencies() Cache Tests
    func testVirtualCurrenciesWithForceRefreshTrueDoesntCheckCachedVirtualCurrencies() async throws {
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
        #warning("TODO")
        XCTAssertTrue(false)
//        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
//        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
//
//        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(
//            forceRefresh: false
//        )
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
//            "isVirtualCurrenciesCacheStale should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
//            1,
//            "cachedVirtualCurrenciesData should be called once when forceTry is false"
//        )
//        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
//                where: {$0 == (self.appUserID, false)}
//            )
//        )
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
//            "cachedVirtualCurrenciesData should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
//            1,
//            "cachedVirtualCurrenciesData should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            virtualCurrencies,
//            self.mockVirtualCurrencies,
//            "Returned virtual currencies should equal the cached virtual currencies"
//        )
    }

    func testVirtualCurrenciesWithForceRefreshFalseReturnsNetworkVirtualCurrenciesWhenCacheIsEmpty() async throws {
        #warning("TODO")
        XCTAssertTrue(false)
//        self.mockDeviceCache.stubbedCachedVirtualCurrenciesDataForAppUserID = self.mockVirtualCurrenciesData
//        self.mockDeviceCache.stubbedIsVirtualCurrenciesCacheStale = false
//
//        let virtualCurrencies: VirtualCurrencies = try await virtualCurrencyManager.virtualCurrencies(
//            forceRefresh: false
//        )
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStale,
//            "isVirtualCurrenciesCacheStale should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleCount,
//            1,
//            "cachedVirtualCurrenciesData should be called once when forceTry is false"
//        )
//        XCTAssertEqual(self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.count, 1)
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedIsVirtualCurrenciesCacheStaleParametersList.contains(
//                where: {$0 == (self.appUserID, false)}
//            )
//        )
//        XCTAssertTrue(
//            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserID,
//            "cachedVirtualCurrenciesData should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            self.mockDeviceCache.invokedCachedVirtualCurrenciesDataForAppUserIDCount,
//            1,
//            "cachedVirtualCurrenciesData should be called when forceTry is false"
//        )
//        XCTAssertEqual(
//            virtualCurrencies,
//            self.mockVirtualCurrencies,
//            "Returned virtual currencies should equal the cached virtual currencies"
//        )
    }

}
