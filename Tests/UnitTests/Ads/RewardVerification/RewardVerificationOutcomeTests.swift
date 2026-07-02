//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationOutcomeTests.swift
//

import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class RewardVerificationOutcomeTests: TestCase {

    func testVerifiedCarriesVirtualCurrencyRewardPayload() throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let outcome = RewardVerification.Outcome.verified(.virtualCurrency(reward))

        guard case let .verified(adReward, moreRewards) = outcome, let captured = adReward.virtualCurrency else {
            return XCTFail("Expected .verified(.virtualCurrency), got \(outcome)")
        }
        XCTAssertEqual(captured, reward)
        XCTAssertEqual(captured.code, "coins")
        XCTAssertEqual(captured.amount, 5)
        XCTAssertTrue(moreRewards.isEmpty)
    }

    func testVerifiedCarriesNoRewardPayload() {
        let outcome = RewardVerification.Outcome.verified(.noReward)

        guard case .verified(.noReward, _) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
    }

    func testVerifiedCarriesUnsupportedRewardPayload() {
        let outcome = RewardVerification.Outcome.verified(.unsupportedReward)

        guard case .verified(.unsupportedReward, _) = outcome else {
            return XCTFail("Expected .verified(.unsupportedReward), got \(outcome)")
        }
    }

    func testFailedReasonsCarryTheirPayloads() {
        let backendRejected = RewardVerification.Outcome.failed(
            .backendRejected(reason: "no_access", message: "nope")
        )
        guard case .failed(.backendRejected("no_access", "nope")) = backendRejected else {
            return XCTFail("Expected .failed(.backendRejected(\"no_access\", \"nope\")), got \(backendRejected)")
        }

        let terminal = RewardVerification.Outcome.failed(.terminalError(error: "boom"))
        guard case .failed(.terminalError("boom")) = terminal else {
            return XCTFail("Expected .failed(.terminalError(\"boom\")), got \(terminal)")
        }
    }

    func testVerifiedCarriesPrimaryRewardAndMoreRewards() throws {
        let primary = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let entitlement = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: Date()))
        let outcome = RewardVerification.Outcome.verified(
            reward: .virtualCurrency(primary),
            moreRewards: [.entitlement(entitlement)]
        )

        guard case let .verified(adReward, moreRewards) = outcome else {
            return XCTFail("Expected .verified, got \(outcome)")
        }
        XCTAssertEqual(adReward.virtualCurrency, primary)
        XCTAssertEqual(moreRewards.count, 1)
        XCTAssertEqual(moreRewards.first?.entitlement, entitlement)
    }
}
