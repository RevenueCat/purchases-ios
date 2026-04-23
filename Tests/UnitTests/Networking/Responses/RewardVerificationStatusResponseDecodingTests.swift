//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationStatusResponseDecodingTests.swift
//
//  Created by Pol Miro on 22/04/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

// swiftlint:disable:next type_name
final class RewardVerificationStatusResponseDecodingTests: TestCase {

    // MARK: - Status decoding

    func testDecodesVerifiedStatus() throws {
        let response = try Self.decode(["status": "verified"])
        expect(response.status) == .verified
    }

    func testDecodesPendingStatus() throws {
        let response = try Self.decode(["status": "pending"])
        expect(response.status) == .pending
    }

    func testDecodesFailedStatus() throws {
        let response = try Self.decode(["status": "failed"])
        expect(response.status) == .failed
    }

    func testDecodesUnrecognizedStatusAsUnknown() throws {
        let unrecognized = "some_future_value"
        let response = try Self.decode(["status": unrecognized])
        expect(response.status) == .unknown

        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError.unknown_reward_verification_status(status: unrecognized).description
                )
            }
        )
    }

    func testDecodesLiteralUnknownStatusAsUnknownAndLogsWarning() throws {
        let rawUnknown = "unknown"
        let response = try Self.decode(["status": rawUnknown])
        expect(response.status) == .unknown

        // The decoder treats a literal `"unknown"` wire value the same as any other
        // unmapped value: it should still emit the warning so we get diagnostics if
        // the backend ever starts sending it.
        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError.unknown_reward_verification_status(status: rawUnknown).description
                )
            }
        )
    }

    // MARK: - Reward payload decoding

    func testDecodesVerifiedWithVirtualCurrencyReward() throws {
        let response = try Self.decode([
            "status": "verified",
            "reward": [
                "type": "virtual_currency",
                "code": "coins",
                "amount": 10
            ]
        ])
        expect(response.status) == .verified
        expect(response.verifiedReward) == .virtualCurrency(VirtualCurrencyReward(code: "coins", amount: 10))
    }

    func testDecodesVerifiedWithVirtualCurrencyRewardPreservesDecimalPrecision() throws {
        let response = try Self.decode([
            "status": "verified",
            "reward": [
                "type": "virtual_currency",
                "code": "gems",
                "amount": Decimal(string: "0.123456789")!
            ]
        ])
        expect(response.verifiedReward)
            == .virtualCurrency(VirtualCurrencyReward(code: "gems", amount: Decimal(string: "0.123456789")!))
    }

    func testDecodesVerifiedWithMissingRewardFieldAsNoReward() throws {
        let response = try Self.decode(["status": "verified"])
        expect(response.status) == .verified
        expect(response.verifiedReward) == .noReward
    }

    func testDecodesVerifiedWithNullRewardAsNoReward() throws {
        let json = #"{"status":"verified","reward":null}"#
        let response = try RewardVerificationStatusResponse.create(with: Data(json.utf8))
        expect(response.status) == .verified
        expect(response.verifiedReward) == .noReward
    }

    func testDecodesVerifiedWithNonObjectRewardAsUnsupportedReward() throws {
        let json = #"{"status":"verified","reward":"not_an_object"}"#
        let response = try RewardVerificationStatusResponse.create(with: Data(json.utf8))
        expect(response.status) == .verified
        expect(response.verifiedReward) == .unsupportedReward
        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError
                        .unexpected_reward_verification_reward_value
                        .description
                )
            }
        )
    }

    func testDecodesVerifiedWithUnknownRewardTypeAsUnsupportedReward() throws {
        let unknownType = "physical_item"
        let response = try Self.decode([
            "status": "verified",
            "reward": [
                "type": unknownType,
                "sku": "tshirt"
            ]
        ])
        expect(response.status) == .verified
        expect(response.verifiedReward) == .unsupportedReward
        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError
                        .unsupported_reward_verification_reward_type(type: unknownType)
                        .description
                )
            }
        )
    }

    func testDecodesVerifiedWithMalformedVirtualCurrencyAsUnsupportedReward() throws {
        let response = try Self.decode([
            "status": "verified",
            "reward": [
                "type": "virtual_currency",
                "code": "coins"
            ]
        ])
        expect(response.status) == .verified
        expect(response.verifiedReward) == .unsupportedReward
        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError
                        .malformed_reward_verification_reward_payload(type: "virtual_currency")
                        .description
                )
            }
        )
    }

    func testNonVerifiedStatusDoesNotCarryReward() throws {
        let response = try Self.decode([
            "status": "pending",
            "reward": [
                "type": "virtual_currency",
                "code": "coins",
                "amount": 10
            ]
        ])
        expect(response.status) == .pending
        expect(response.verifiedReward).to(beNil())
    }

    private static func decode(_ json: [String: Any]) throws -> RewardVerificationStatusResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try RewardVerificationStatusResponse.create(with: data)
    }

}
