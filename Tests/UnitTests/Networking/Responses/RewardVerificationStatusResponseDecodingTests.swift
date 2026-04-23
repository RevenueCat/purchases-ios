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

@testable import RevenueCat

// swiftlint:disable:next type_name
final class RewardVerificationStatusResponseDecodingTests: TestCase {

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

        // Guard the warning log: a future refactor that drops the warning would silently
        // strip diagnostics for unmapped backend status values, so this is asserted here
        // (mirroring `testGetRewardVerificationStatusUnknownStatusDecodesAsUnknown`).
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

    private static func decode(_ json: [String: Any]) throws -> RewardVerificationStatusResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try RewardVerificationStatusResponse.create(with: data)
    }

}
