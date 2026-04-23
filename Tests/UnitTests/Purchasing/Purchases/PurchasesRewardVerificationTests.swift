//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesRewardVerificationTests.swift
//
//  Created by RevenueCat on 4/21/26.
//

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@MainActor
final class PurchasesRewardVerificationTests: BasePurchasesTests {

    private var mockAdsAPI: MockAdsAPI {
        get throws {
            return try XCTUnwrap(self.backend.adsAPI as? MockAdsAPI)
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.setupPurchases()
    }

    func testPollRewardVerificationStatusMapsUnknownStatusToUnknown() async throws {
        let transactionID = "AABBCCDD-1111-2222-3333-444455556666"
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(.init(status: .unknown))

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: transactionID)

        expect(status) == .unknown
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusCount) == 1
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusParameters?.appUserID)
            == self.identityManager.currentAppUserID
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusParameters?.clientTransactionID) == transactionID
    }

    func testPollRewardVerificationStatusMapsVerifiedStatusWithVirtualCurrencyReward() async throws {
        let reward = VirtualCurrencyReward(code: "coins", amount: 10)
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified, verifiedReward: .virtualCurrency(reward))
        )

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.virtualCurrency(reward))
    }

    func testPollRewardVerificationStatusMapsVerifiedStatusWithNoReward() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified, verifiedReward: .noReward)
        )

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.noReward)
    }

    func testPollRewardVerificationStatusMapsVerifiedStatusWithUnsupportedReward() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified, verifiedReward: .unsupportedReward)
        )

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.unsupportedReward)
    }

    func testPollRewardVerificationStatusVerifiedWithoutRewardFallsBackToNoReward() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified, verifiedReward: nil)
        )

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.noReward)
    }

    func testPollRewardVerificationStatusMapsPendingStatus() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(.init(status: .pending))

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .pending
    }

    func testPollRewardVerificationStatusMapsFailedStatus() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(.init(status: .failed))

        let status = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .failed
    }

    func testPollRewardVerificationStatusForwardsBackendError() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .failure(backendError)

        do {
            _ = try await self.purchases.pollRewardVerificationStatus(clientTransactionID: "tx-id")
            fail("Expected pollRewardVerificationStatus to throw")
        } catch {
            expect(error).to(matchError(backendError.asPurchasesError))
        }
    }

}
