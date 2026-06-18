//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationStatusResponseTests.swift
//

import Foundation
import Nimble
import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

/// Decoding tests for the reward-verification poll response wire shape (`reward` + `more_rewards`).
final class RewardVerificationStatusResponseTests: TestCase {

    private static let expiresAtString = "2026-06-16T12:00:00Z"
    private static let expiresAt = ISO8601DateFormatter().date(from: expiresAtString)!

    private func decode(_ json: [String: Any]) throws -> RewardVerificationStatusResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try RewardVerificationStatusResponse.create(with: data)
    }

    // MARK: - Status

    func testDecodesPendingStatus() throws {
        expect(try self.decode(["status": "pending"]).status) == .pending
    }

    func testDecodesFailedStatus() throws {
        expect(try self.decode(["status": "failed"]).status) == .failed(.init(reason: nil, message: nil))
    }

    func testDecodesUnknownStatus() throws {
        expect(try self.decode(["status": "some_future_state"]).status) == .unknown
    }

    // MARK: - Primary reward

    func testDecodesVirtualCurrencyReward() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        guard case let .verified(reward, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(reward.virtualCurrency) == VirtualCurrencyReward(code: "coins", amount: 10)
        expect(moreRewards).to(beEmpty())
    }

    func testDecodesEntitlementReward() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "entitlement", "identifier": "pro", "expires_at": Self.expiresAtString]
        ])

        guard case let .verified(reward, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        let entitlement = try XCTUnwrap(reward.entitlement)
        expect(entitlement.identifier) == "pro"
        expect(entitlement.expiresAt) == Self.expiresAt
        expect(moreRewards).to(beEmpty())
    }

    func testVerifiedWithoutRewardDecodesAsNoReward() throws {
        let response = try self.decode(["status": "verified"])
        expect(response.status) == .verified(.noReward)
    }

    func testMalformedEntitlementDecodesAsUnsupported() throws {
        // Entitlement reward missing its `identifier`.
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "entitlement", "expires_at": Self.expiresAtString]
        ])
        expect(response.status) == .verified(.unsupportedReward)
        self.logger.verifyMessageWasLogged(
            Strings.backendError.malformed_reward_verification_reward_payload(type: "entitlement"),
            level: .warn
        )
    }

    func testEntitlementMissingExpiresAtDecodesAsUnsupported() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "entitlement", "identifier": "pro"]
        ])
        expect(response.status) == .verified(.unsupportedReward)
        self.logger.verifyMessageWasLogged(
            Strings.backendError.malformed_reward_verification_reward_payload(type: "entitlement"),
            level: .warn
        )
    }

    func testEntitlementInvalidExpiresAtDecodesAsUnsupported() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "entitlement", "identifier": "pro", "expires_at": "not-a-date"]
        ])
        expect(response.status) == .verified(.unsupportedReward)
        self.logger.verifyMessageWasLogged(
            Strings.backendError.malformed_reward_verification_reward_payload(type: "entitlement"),
            level: .warn
        )
    }

    func testUnknownPrimaryRewardTypeDecodesAsUnsupported() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "some_future_reward"]
        ])
        expect(response.status) == .verified(.unsupportedReward)
        self.logger.verifyMessageWasLogged(
            Strings.backendError.unsupported_reward_verification_reward_type(type: "some_future_reward"),
            level: .warn
        )
    }

    // MARK: - moreRewards

    func testMultiGrantDecodesPrimaryAndMoreRewards() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": [
                ["type": "entitlement", "identifier": "pro", "expires_at": Self.expiresAtString]
            ]
        ])

        guard case let .verified(reward, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(reward.virtualCurrency) == VirtualCurrencyReward(code: "coins", amount: 10)
        expect(moreRewards).to(haveCount(1))
        let entitlement = try XCTUnwrap(moreRewards.first?.entitlement)
        expect(entitlement.identifier) == "pro"
        expect(entitlement.expiresAt) == Self.expiresAt
    }

    func testAbsentMoreRewardsDecodesAsEmpty() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        guard case let .verified(_, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(moreRewards).to(beEmpty())
    }

    func testUnknownTypeInMoreRewardsDecodesAsUnsupportedEntry() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": [["type": "some_future_reward"]]
        ])

        guard case let .verified(_, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(moreRewards) == [.unsupportedReward]
        self.logger.verifyMessageWasLogged(
            Strings.backendError.unsupported_reward_verification_reward_type(type: "some_future_reward"),
            level: .warn
        )
    }

    func testMultipleMoreRewardsPreserveOrder() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": [
                ["type": "entitlement", "identifier": "pro", "expires_at": Self.expiresAtString],
                ["type": "virtual_currency", "code": "gems", "amount": 5]
            ]
        ])

        guard case let .verified(_, moreRewards) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(moreRewards).to(haveCount(2))
        expect(moreRewards[0].entitlement?.identifier) == "pro"
        expect(moreRewards[1].virtualCurrency) == VirtualCurrencyReward(code: "gems", amount: 5)
    }
}
