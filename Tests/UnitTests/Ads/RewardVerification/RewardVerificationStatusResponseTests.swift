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

/// Decoding tests for the reward-verification poll response wire shape.
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

    // MARK: - Reward

    func testDecodesVirtualCurrencyReward() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        guard case let .verified(reward) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        expect(reward.virtualCurrency) == VirtualCurrencyReward(code: "coins", amount: 10)
    }

    func testDecodesEntitlementReward() throws {
        let response = try self.decode([
            "status": "verified",
            "reward": ["type": "entitlement", "identifier": "pro", "expires_at": Self.expiresAtString]
        ])

        guard case let .verified(reward) = response.status else {
            return fail("Expected verified, got \(response.status)")
        }
        let entitlement = try XCTUnwrap(reward.entitlement)
        expect(entitlement.identifier) == "pro"
        expect(entitlement.expiresAt) == Self.expiresAt
    }

    func testVerifiedWithoutRewardDecodesAsNoReward() throws {
        expect(try self.decode(["status": "verified"]).status) == .verified(.noReward)
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

    func testUnknownRewardTypeDecodesAsUnsupported() throws {
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
}
