//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManagerUIPreviewModeTests.swift
//
//  Created by Antonio Pallares on 14/2/25.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomerInfoManagerUIPreviewModeTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {

        // Enable UI Preview Mode
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            dangerousSettings: DangerousSettings(uiPreviewMode: true),
            preferredLocalesProvider: .mock()
        )

        try super.setUpWithError()
    }

    func testFetchCustomerInfoDoesNotCallBackendInUIPreviewMode() async throws {
        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    func testCustomerInfoIsNotCachedInUIPreviewMode() async throws {
        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 0
    }

    func testCachedCustomerInfoInUIPreviewModeReturnsMockCustomerInfo() async throws {
        let info = try XCTUnwrap(self.customerInfoManager.cachedCustomerInfo(appUserID: "any_user"))

        expect(info.originalAppUserId) == IdentityManager.uiPreviewModeAppUserID
    }

    func testUIPreviewModeCustomerInfoHasExpectedValues() async throws {
        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(info.originalAppUserId) == IdentityManager.uiPreviewModeAppUserID
    }

    func testCustomerInfoReturnsMockInUIPreviewModeForAllFetchPolicies() async throws {
        let policies: [CacheFetchPolicy] = [
            .fromCacheOnly,
            .fetchCurrent,
            .cachedOrFetched,
            .notStaleCachedOrFetched
        ]

        for policy in policies {
            let info = try await self.customerInfoManager.customerInfo(
                appUserID: "any_user",
                trackDiagnostics: false,
                fetchPolicy: policy
            )

            expect(self.mockBackend.invokedGetSubscriberData) == false
            expect(info.originalAppUserId) == IdentityManager.uiPreviewModeAppUserID
            expect(self.mockDeviceCache.cacheCustomerInfoCount) == 0
        }
    }

    func testUnfinishedTransactionsIgnoredInUIPreviewMode() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [
            Self.createTransaction(),
            Self.createTransaction()
        ]

        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(
            appUserID: "any_user",
            isAppBackgrounded: false
        )

        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
        expect(info.originalAppUserId) == IdentityManager.uiPreviewModeAppUserID
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension CustomerInfoManagerUIPreviewModeTests {

    static func createTransaction() -> StoreTransaction {
        return .init(sk1Transaction: MockTransaction())
    }

}
