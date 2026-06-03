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
    }

    func testFetchCustomerInfoReachesBackendInSimulatedStoreMode() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockBackend.invokedGetSubscriberData) == true
    }

    func testFetchCustomerInfoDoesNotReadStoreKitTransactionsInSimulatedStoreMode() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockTransationFetcher.invokedUnfinishedVerifiedTransactions.value) == false
    }

    func testUnfinishedTransactionsIgnoredInSimulatedStoreMode() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [
            Self.createTransaction(),
            Self.createTransaction()
        ]
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockTransationFetcher.invokedUnfinishedVerifiedTransactions.value) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
        expect(self.mockBackend.invokedGetSubscriberData) == true
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension CustomerInfoManagerSimulatedStoreTests {

    static func createTransaction() -> StoreTransaction {
        return .init(sk1Transaction: MockTransaction())
    }

}
