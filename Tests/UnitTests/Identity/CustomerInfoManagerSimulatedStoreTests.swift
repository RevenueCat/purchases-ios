//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManagerSimulatedStoreTests.swift

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomerInfoManagerSimulatedStoreTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {

        // Use a Simulated Store ("Test Store") API key
        self.mockSystemInfo = MockSystemInfo(
            finishTransactions: true,
            apiKeyValidationResult: .simulatedStore
        )

        try super.setUpWithError()

        // Mirror production: in Simulated Store mode the `SimulatedStoreTransactionFetcher` is
        // injected, which never returns any StoreKit transactions.
        self.customerInfoManager = CustomerInfoManager(
            offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
            operationDispatcher: self.mockOperationDispatcher,
            deviceCache: self.mockDeviceCache,
            backend: self.mockBackend,
            transactionFetcher: SimulatedStoreTransactionFetcher(),
            transactionPoster: self.mockTransactionPoster,
            systemInfo: self.mockSystemInfo
        )
    }

    func testFetchCustomerInfoReachesBackendInSimulatedStoreMode() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockBackend.invokedGetSubscriberData) == true
    }

    func testSimulatedStoreFetcherReturnsNoTransactionsSoCustomerInfoComesFromBackend() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        // The `SimulatedStoreTransactionFetcher` returns no transactions, so CustomerInfo is
        // fetched from the backend and no transaction is posted.
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
        expect(self.mockBackend.invokedGetSubscriberData) == true
    }
}
