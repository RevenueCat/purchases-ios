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
        self.backend.overrideCustomerInfoResult = .failure(makeTerminalBackendError())
        let before = self.backend.getCustomerInfoCallCount
        let poller = self.makeStubPoller(statuses: [.verified(.entitlement(reward))])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .failed
        expect(result.verifiedReward).to(beNil())
        expect(self.backend.getCustomerInfoCallCount) == before + 1
        self.logger.verifyMessageWasLogged(
            AdsStrings.reward_verification_completed(result: .failed, transactionID: "tx-1"),
            level: .info
        )
        self.logger.verifyMessageWasNotLogged(
            AdsStrings.reward_verification_completed(
                result: .verified(.entitlement(reward)), transactionID: "tx-1"
            )
        )
    }

    func testTransientServerErrorsAreRetriableForEntitlementRefresh() {
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

    func testPollRewardVerificationMultiGrantInvalidatesVCCacheAndFetchesCustomerInfo() async throws {
        let virtualCurrency = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let entitlement = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        let before = self.backend.getCustomerInfoCallCount
        let poller = self.makeStubPoller(statuses: [
            .verified(reward: .virtualCurrency(virtualCurrency), moreRewards: [.entitlement(entitlement)])
        ])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 1
        expect(self.backend.getCustomerInfoCallCount) > before
        expect(result.verifiedReward) == .virtualCurrency(virtualCurrency)
        expect(result.moreRewards) == [.entitlement(entitlement)]
    }

    func testPollRewardVerificationMultiGrantFailsWhenEntitlementRefreshFails() async throws {
        let virtualCurrency = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let entitlement = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        self.backend.overrideCustomerInfoResult = .failure(makeTerminalBackendError())
        let poller = self.makeStubPoller(statuses: [
            .verified(reward: .virtualCurrency(virtualCurrency), moreRewards: [.entitlement(entitlement)])
        ])

        let result = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        expect(result) == .failed
        expect(self.mockVirtualCurrencyManager.invalidateVirtualCurrenciesCacheCallCount) == 1
    }

}

// MARK: - pollRewardVerification tracking

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PurchasesRewardVerificationTests {

    private func makeTrackingMetadata() -> RewardedAdTrackingMetadata {
        .init(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )
    }

    func testPollRewardVerificationWithNilTrackingMetadataTracksNothing() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 3))
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        _ = await self.purchases.pollRewardVerification(clientTransactionID: "tx-1", poller: poller)

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(beEmpty())
    }

    func testPollRewardVerificationTracksEarnedUnverifiedEvent() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 3))
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        _ = await self.purchases.pollRewardVerification(
            clientTransactionID: "tx-1",
            trackingMetadata: self.makeTrackingMetadata(),
            poller: poller
        )

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(3))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents // earned, verified, granted
        guard case let .rewardEarnedUnverified(_, eventData) = trackedEvents.first else {
            return fail("Expected AdEvent.rewardEarnedUnverified but got \(String(describing: trackedEvents.first))")
        }
        expect(eventData.networkName) == "AdMob"
        expect(eventData.mediatorName) == .adMob
        expect(eventData.adFormat) == .rewarded
        expect(eventData.placement) == "home_screen"
        expect(eventData.adUnitId) == "ca-app-pub-123"
        expect(eventData.impressionId) == "impression-123"
        expect(eventData.rewardVerificationEnabled) == true
    }

    func testPollRewardVerificationTracksVerifiedAndGrantedEventsOnVirtualCurrencyReward() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 3))
        let poller = self.makeStubPoller(statuses: [.verified(.virtualCurrency(reward))])

        _ = await self.purchases.pollRewardVerification(
            clientTransactionID: "tx-1",
            trackingMetadata: self.makeTrackingMetadata(),
            poller: poller
        )

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(3))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents // earned, verified, granted
        guard case let .rewardVerified(_, verifiedData) = trackedEvents[1] else {
            return fail("Expected AdEvent.rewardVerified but got \(trackedEvents[1])")
        }
        expect(verifiedData.reward.virtualCurrency?.code) == "coins"

        guard case let .rewardGranted(_, grantedData) = trackedEvents[2] else {
            return fail("Expected AdEvent.rewardGranted but got \(trackedEvents[2])")
        }
        expect(grantedData.reward.virtualCurrency?.code) == "coins"
    }

    func testPollRewardVerificationDoesNotTrackGrantedEventOnNoReward() async throws {
        let poller = self.makeStubPoller(statuses: [.verified(.noReward)])

        _ = await self.purchases.pollRewardVerification(
            clientTransactionID: "tx-1",
            trackingMetadata: self.makeTrackingMetadata(),
            poller: poller
        )

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(2))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents // earned, verified — no granted
        expect(trackedEvents.contains { if case .rewardGranted = $0 { return true }; return false }) == false
    }

    func testPollRewardVerificationTracksOneGrantedEventPerRewardOnMultiGrant() async throws {
        let virtualCurrency = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let entitlement = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        let poller = self.makeStubPoller(statuses: [
            .verified(reward: .virtualCurrency(virtualCurrency), moreRewards: [.entitlement(entitlement)])
        ])

        _ = await self.purchases.pollRewardVerification(
            clientTransactionID: "tx-1",
            trackingMetadata: self.makeTrackingMetadata(),
            poller: poller
        )

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(4))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents
        let grantedEvents = trackedEvents.compactMap { event -> AdRewardGranted? in
            guard case let .rewardGranted(_, data) = event else { return nil }
            return data
        }
        expect(grantedEvents.count) == 2
        expect(grantedEvents.map(\.reward)) == [.virtualCurrency(virtualCurrency), .entitlement(entitlement)]
    }

    func testPollRewardVerificationTracksFailedToVerifyEvent() async throws {
        let poller = self.makeStubPoller(statuses: [.failed(reason: "no_reward_rule", message: "nope")])

        _ = await self.purchases.pollRewardVerification(
            clientTransactionID: "tx-1",
            trackingMetadata: self.makeTrackingMetadata(),
            poller: poller
        )

        await expect { try await self.mockEventsManager.trackedAdEvents }.toEventually(haveCount(2))

        let trackedEvents = try await self.mockEventsManager.trackedAdEvents // earned, failed-to-verify
        guard case let .rewardFailedToVerify(_, failedData) = trackedEvents[1] else {
            return fail("Expected AdEvent.rewardFailedToVerify but got \(trackedEvents[1])")
        }
        expect(failedData.failureReason) == .backendError
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
