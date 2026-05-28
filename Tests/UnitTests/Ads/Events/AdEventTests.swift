//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventTests.swift
//
//  Created by RevenueCat on 1/23/26.

import Nimble
import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdEventTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    // MARK: - AdFailedToLoad Equality

    func testAdFailedToLoadEqualityWithDifferentAdFormat() {
        let event1 = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let event2 = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        expect(event1) != event2
    }

    func testAdFailedToLoadEqualityWithSameProperties() {
        let event1 = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        let event2 = AdFailedToLoad(
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            mediatorErrorCode: 3
        )

        expect(event1) == event2
    }

    // MARK: - AdLoaded Equality

    func testAdLoadedEqualityWithDifferentAdFormat() {
        let event1 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdLoadedEqualityWithSameProperties() {
        let event1 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdLoaded(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .interstitial,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdDisplayed Equality

    func testAdDisplayedEqualityWithDifferentAdFormat() {
        let event1 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdDisplayedEqualityWithSameProperties() {
        let event1 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdDisplayed(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdOpened Equality

    func testAdOpenedEqualityWithDifferentAdFormat() {
        let event1 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .appOpen,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) != event2
    }

    func testAdOpenedEqualityWithSameProperties() {
        let event1 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        let event2 = AdOpened(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .native,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123"
        )

        expect(event1) == event2
    }

    // MARK: - AdRevenue Equality

    func testAdRevenueEqualityWithDifferentAdFormat() {
        let event1 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        let event2 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .other,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        expect(event1) != event2
    }

    func testAdRevenueEqualityWithSameProperties() {
        let event1 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .other,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        let event2 = AdRevenue(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .other,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            revenueMicros: 1500000,
            currency: "USD",
            precision: .exact
        )

        expect(event1) == event2
    }

    // MARK: - AdRewardEarnedUnverified Equality

    func testAdRewardEarnedUnverifiedEqualityWithDifferentRewardAmount() {
        let event1 = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 10
        )

        let event2 = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 20
        )

        expect(event1) != event2
    }

    func testAdRewardEarnedUnverifiedEqualityWithSameProperties() {
        let event1 = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 10
        )

        let event2 = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 10
        )

        expect(event1) == event2
    }

    func testAdRewardEarnedUnverifiedAllowsNilRewardFields() {
        let event = AdRewardEarnedUnverified(
            networkName: nil,
            mediatorName: .adMob,
            adFormat: .rewardedInterstitial,
            placement: nil,
            adUnitId: "ca-app-pub-123",
            impressionId: "",
            rewardVerificationEnabled: false,
            rewardItem: nil,
            rewardAmount: nil as Int?
        )

        expect(event.rewardItem).to(beNil())
        expect(event.rewardAmount).to(beNil())
        expect(event.rewardVerificationEnabled) == false
    }

    // MARK: - AdRewardVerified Equality

    func testAdRewardVerifiedEqualityWithDifferentRewardType() {
        let event1 = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .virtualCurrency(code: "GOLD", amount: 100)
        )

        let event2 = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .noReward
        )

        expect(event1) != event2
    }

    func testAdRewardVerifiedEqualityWithSameProperties() {
        let event1 = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .virtualCurrency(code: "GOLD", amount: 100)
        )

        let event2 = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .virtualCurrency(code: "GOLD", amount: 100)
        )

        expect(event1) == event2
    }

    func testAdRewardVerifiedNoRewardHasNoVirtualCurrencyPayload() {
        let event = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: nil,
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .noReward
        )

        expect(event.reward.virtualCurrency).to(beNil())
        expect(event.reward) == AdReward.noReward
    }

    // MARK: - AdRewardFailedToVerify Equality

    func testAdRewardFailedToVerifyEqualityWithDifferentFailureReason() {
        let event1 = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .timeout
        )

        let event2 = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .backendError
        )

        expect(event1) != event2
    }

    func testAdRewardFailedToVerifyEqualityWithSameProperties() {
        let event1 = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .timeout
        )

        let event2 = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .timeout
        )

        expect(event1) == event2
    }

    // MARK: - AdReward / AdRewardFailureReason rawValue stability

    func testAdRewardKindRawValuesAreStable() {
        expect(AdReward.virtualCurrency(code: "x", amount: 1).kindRawValue) == "virtual_currency"
        expect(AdReward.noReward.kindRawValue) == "no_reward"
        expect(AdReward.unsupportedReward.kindRawValue) == "unsupported_reward"
    }

    func testAdRewardFailureReasonStaticConstantsHaveStableRawValues() {
        expect(AdRewardFailureReason.timeout.rawValue) == "timeout"
        expect(AdRewardFailureReason.networkError.rawValue) == "network_error"
        expect(AdRewardFailureReason.backendError.rawValue) == "backend_error"
        expect(AdRewardFailureReason.unknown.rawValue) == "unknown"
    }

    // MARK: - Codable round-trip

    func testAdRewardEarnedUnverifiedCodableRoundTrip() throws {
        let original = AdRewardEarnedUnverified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            rewardVerificationEnabled: true,
            rewardItem: "coins",
            rewardAmount: 10
        )

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(AdRewardEarnedUnverified.self, from: data)

        expect(decoded) == original
    }

    func testAdRewardVerifiedCodableRoundTrip() throws {
        let original = AdRewardVerified(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            reward: .virtualCurrency(code: "GOLD", amount: 100)
        )

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(AdRewardVerified.self, from: data)

        expect(decoded) == original
    }

    func testAdRewardFailedToVerifyCodableRoundTrip() throws {
        let original = AdRewardFailedToVerify(
            networkName: "AdMob",
            mediatorName: .adMob,
            adFormat: .rewarded,
            placement: "home_screen",
            adUnitId: "ca-app-pub-123",
            impressionId: "impression-123",
            failureReason: .backendError
        )

        let data = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(AdRewardFailedToVerify.self, from: data)

        expect(decoded) == original
    }

}

// MARK: - AdRewardVerified Decoder Fallbacks

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension AdEventTests {

    private func decodeAdRewardVerified(rewardFields: String) throws -> AdRewardVerified {
        let json = """
        {
            "network_name": "AdMob",
            "mediator_name": { "raw_value": "AdMob" },
            "ad_format": { "raw_value": "rewarded" },
            "placement": "home_screen",
            "ad_unit_id": "ca-app-pub-123",
            "impression_id": "impression-123",
            \(rewardFields)
        }
        """
        return try JSONDecoder.default.decode(AdRewardVerified.self, from: Data(json.utf8))
    }

    func testAdRewardVerifiedDecodingUnknownRewardKindFallsBackToUnsupported() throws {
        let decoded = try decodeAdRewardVerified(rewardFields: "\"reward_type\": \"future_reward_kind\"")
        expect(decoded.reward) == .unsupportedReward
    }

    func testAdRewardVerifiedDecodingVirtualCurrencyWithMissingAmountFallsBackToUnsupported() throws {
        let decoded = try decodeAdRewardVerified(
            rewardFields: "\"reward_type\": \"virtual_currency\", \"reward_currency_code\": \"GOLD\""
        )
        expect(decoded.reward) == .unsupportedReward
    }

    func testAdRewardVerifiedDecodingVirtualCurrencyWithNonPositiveAmountFallsBackToUnsupported() throws {
        let decoded = try decodeAdRewardVerified(
            rewardFields: """
            "reward_type": "virtual_currency", "reward_currency_code": "GOLD", "reward_currency_amount": 0
            """
        )
        expect(decoded.reward) == .unsupportedReward
    }

}
