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

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

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

    func testFetchRewardVerificationStatusMapsUnknownStatusToUnknown() async throws {
        let transactionID = "AABBCCDD-1111-2222-3333-444455556666"
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(.init(status: .unknown))

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: transactionID)

        expect(status) == .unknown
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusCount) == 1
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusParameters?.appUserID)
            == self.identityManager.currentAppUserID
        expect(try self.mockAdsAPI.invokedGetRewardVerificationStatusParameters?.clientTransactionID) == transactionID
    }

    func testFetchRewardVerificationStatusMapsVerifiedStatusWithVirtualCurrencyReward() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 10))
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified(.virtualCurrency(reward)))
        )

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.virtualCurrency(reward))
    }

    func testFetchRewardVerificationStatusMapsVerifiedStatusWithNoReward() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified(.noReward))
        )

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.noReward)
    }

    func testFetchRewardVerificationStatusMapsVerifiedStatusWithUnsupportedReward() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .verified(.unsupportedReward))
        )

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .verified(.unsupportedReward)
    }

    func testFetchRewardVerificationStatusMapsPendingStatus() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(.init(status: .pending))

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .pending
    }

    func testFetchRewardVerificationStatusMapsFailedStatus() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .failed(.init(reason: nil, message: nil)))
        )

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .failed(reason: nil, message: nil)
    }

    func testFetchRewardVerificationStatusForwardsFailureReasonAndMessage() async throws {
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .success(
            .init(status: .failed(.init(
                reason: "no_access",
                message: "AdMob server-side reward verification is not enabled for this app."
            )))
        )

        let status = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")

        expect(status) == .failed(
            reason: "no_access",
            message: "AdMob server-side reward verification is not enabled for this app."
        )
    }

    func testFetchRewardVerificationStatusForwardsBackendError() async throws {
        let backendError: BackendError = .networkError(.offlineConnection())
        try self.mockAdsAPI.stubbedGetRewardVerificationStatusResult = .failure(backendError)

        do {
            _ = try await self.purchases.fetchRewardVerificationStatus(clientTransactionID: "tx-id")
            fail("Expected fetchRewardVerificationStatus to throw")
        } catch {
            expect(error).to(matchError(backendError))
        }
    }

}

// MARK: - pollRewardVerification

extension PurchasesRewardVerificationTests {

    private func makeStubPoller(statuses: [RewardVerificationPollStatus]) -> RewardVerification.Poller {
        makePoller(statusPoller: StubStatusPoller(statuses: statuses), sleeper: RecordingSleeper())
    }

    func testPollRewardVerificationReturnsVerifiedWithVirtualCurrencyReward() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 3))
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result.verifiedReward) == .virtualCurrency(reward)
    }

    func testPollRewardVerificationReturnsVerifiedWithNoReward() async {
        let poller = self.makeStubPoller(statuses: [.verified(.noReward)])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .verified(.noReward)
    }

    func testPollRewardVerificationReturnsVerifiedWithUnsupportedReward() async {
        let poller = self.makeStubPoller(statuses: [.verified(.unsupportedReward)])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .verified(.unsupportedReward)
    }

    func testPollRewardVerificationReturnsFailed() async {
        let poller = self.makeStubPoller(statuses: [.failed(reason: nil, message: nil)])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .failed
    }

    func testPollRewardVerificationInvalidatesVirtualCurrenciesCacheOnVirtualCurrencyReward() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 4))
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 1
    }

    func testPollRewardVerificationDoesNotInvalidateCacheOnNoReward() async {
        let poller = self.makeStubPoller(statuses: [.verified(.noReward)])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 0
    }

    func testPollRewardVerificationDoesNotInvalidateCacheOnUnsupportedReward() async {
        let poller = self.makeStubPoller(statuses: [.verified(.unsupportedReward)])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 0
    }

    func testPollRewardVerificationDoesNotInvalidateCacheOnFailed() async {
        let poller = self.makeStubPoller(statuses: [.failed(reason: nil, message: nil)])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 0
    }

    func testPollRewardVerificationFetchesCustomerInfoOnEntitlementReward() async throws {
        let reward = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        let before = self.backend.getCustomerInfoCallCount
        let poller = self.makeStubPoller(statuses: [.verified(.entitlement(reward))])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result.verifiedReward) == .entitlement(reward)
        expect(self.backend.getCustomerInfoCallCount) > before
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 0
    }

    func testPollRewardVerificationFailsWhenEntitlementCustomerInfoRefreshFails() async throws {
        let reward = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        // Terminal (non-transient) error — should not be retried.
        self.backend.overrideCustomerInfoResult = .failure(makeTerminalBackendError())
        let before = self.backend.getCustomerInfoCallCount
        let poller = self.makeStubPoller(statuses: [.verified(.entitlement(reward))])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .failed
        expect(result.verifiedReward).to(beNil())
        expect(self.backend.getCustomerInfoCallCount) == before + 1
        // The completion log reflects the delivered result, never "verified".
        self.logger.verifyMessageWasLogged(
            AdsStrings.reward_verification_completed(
                outcome: "failed(entitlementRefreshFailed)", transactionID: "tx-1"
            ),
            level: .info
        )
        self.logger.verifyMessageWasNotLogged(
            AdsStrings.reward_verification_completed(outcome: "verified", transactionID: "tx-1")
        )
    }

    func testTransientServerErrorsAreRetriableForEntitlementRefresh() {
        // Typical transient infra errors (502, 503) must be retried, not treated as terminal.
        for statusCode in [502, 503] {
            let error = makePollingError(statusCode: statusCode, backendCode: .internalServerError)
            expect(error.isTransient).to(beTrue(), description: "status \(statusCode) should be transient")
        }
    }

    func testPollRewardVerificationDoesNotFetchCustomerInfoOnVirtualCurrencyReward() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 4))
        let before = self.backend.getCustomerInfoCallCount
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.backend.getCustomerInfoCallCount) == before
    }

}

// MARK: - generateRewardVerificationToken

extension PurchasesRewardVerificationTests {

    func testGenerateRewardVerificationTokenReturnsValidUUID() {
        let token = self.purchases.generateRewardVerificationToken(impressionId: "imp-1")
        expect(UUID(uuidString: token.clientTransactionID)).toNot(beNil())
    }

    func testGenerateRewardVerificationTokenCustomDataContainsExpectedFields() throws {
        let impressionId = "imp-123"
        let token = self.purchases.generateRewardVerificationToken(impressionId: impressionId)

        let data = try XCTUnwrap(token.customData.data(using: .utf8))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])

        expect(json["impression_id"]) == impressionId
        expect(json["client_transaction_id"]) == token.clientTransactionID
        expect(json["api_key"]?.isEmpty) == false
    }

    func testGenerateRewardVerificationTokenCustomDataHasSortedKeys() {
        let token = self.purchases.generateRewardVerificationToken(impressionId: "imp-789")
        // api_key < client_transaction_id < impression_id alphabetically
        expect(token.customData.hasPrefix("{\"api_key\":")) == true
    }

    func testGenerateRewardVerificationTokenReturnsCurrentAppUserID() {
        let token = self.purchases.generateRewardVerificationToken(impressionId: "imp-1")
        expect(token.appUserID) == self.identityManager.currentAppUserID
    }

    func testGenerateRewardVerificationTokenGeneratesUniqueTransactionIds() {
        let first = self.purchases.generateRewardVerificationToken(impressionId: "imp-1")
        let second = self.purchases.generateRewardVerificationToken(impressionId: "imp-1")
        expect(first.clientTransactionID) != second.clientTransactionID
    }

}
