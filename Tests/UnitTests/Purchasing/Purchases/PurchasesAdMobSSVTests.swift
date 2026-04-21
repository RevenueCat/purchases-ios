//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesAdMobSSVTests.swift
//
//  Created by RevenueCat on 4/21/26.
//

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@MainActor
final class PurchasesAdMobSSVTests: BasePurchasesTests {

    private var mockAdsAPI: MockAdsAPI {
        get throws {
            return try XCTUnwrap(self.backend.adsAPI as? MockAdsAPI)
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.setupPurchases()
    }

    func testPollAdMobSSVStatusMapsUnknownStatusToPending() async throws {
        let transactionID = "AABBCCDD-1111-2222-3333-444455556666"
        try self.mockAdsAPI.stubbedGetAdMobSSVStatusResult = .success(.init(status: .unknown))

        let status = try await self.purchases.pollAdMobSSVStatus(clientTransactionID: transactionID)

        expect(status) == .pending
        expect(try self.mockAdsAPI.invokedGetAdMobSSVStatusCount) == 1
        expect(try self.mockAdsAPI.invokedGetAdMobSSVStatusParameters?.appUserID)
            == self.identityManager.currentAppUserID
        expect(try self.mockAdsAPI.invokedGetAdMobSSVStatusParameters?.clientTransactionID) == transactionID
    }

    func testPollAdMobSSVStatusMapsValidatedStatus() async throws {
        try self.mockAdsAPI.stubbedGetAdMobSSVStatusResult = .success(.init(status: .validated))

        let status = try await self.purchases.pollAdMobSSVStatus(clientTransactionID: "tx-id")

        expect(status) == .validated
    }

    func testPollAdMobSSVStatusMapsPendingStatus() async throws {
        try self.mockAdsAPI.stubbedGetAdMobSSVStatusResult = .success(.init(status: .pending))

        let status = try await self.purchases.pollAdMobSSVStatus(clientTransactionID: "tx-id")

        expect(status) == .pending
    }

    func testPollAdMobSSVStatusMapsFailedStatus() async throws {
        try self.mockAdsAPI.stubbedGetAdMobSSVStatusResult = .success(.init(status: .failed))

        let status = try await self.purchases.pollAdMobSSVStatus(clientTransactionID: "tx-id")

        expect(status) == .failed
    }

    func testPollAdMobSSVStatusForwardsBackendError() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        try self.mockAdsAPI.stubbedGetAdMobSSVStatusResult = .failure(backendError)

        do {
            _ = try await self.purchases.pollAdMobSSVStatus(clientTransactionID: "tx-id")
            fail("Expected pollAdMobSSVStatus to throw")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
    }

}
