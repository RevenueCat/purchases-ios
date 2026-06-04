//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationStatusResponse.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

struct RewardVerificationStatusResponse: Equatable {

    let status: Status

    enum Status: Equatable {

        case verified(AdReward)
        case pending
        case failed(Failure)
        case unknown

    }

    /// Backend-provided detail accompanying a `failed` status.
    ///
    /// Both fields are optional: older backends (and the no-record/feature-off paths) may omit them.
    struct Failure: Equatable {

        /// Raw `failure_reason` wire value (e.g. `no_access`). Stored as-is for forward
        /// compatibility — unrecognized values are kept rather than dropped. `nil` when absent.
        let reason: String?

        /// Human-readable cause, logged verbatim. `nil` when absent.
        let message: String?

    }
}

extension RewardVerificationStatusResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case status
        case reward
        // `JSONDecoder.default` uses `.convertFromSnakeCase`, so the wire key `failure_reason`
        // is converted to `failureReason` before matching — use the camelCase name here.
        case failureReason
        case message
    }

    private enum RewardCodingKeys: String, CodingKey {
        case type
        case code
        case amount
    }

    private enum RewardType {
        static let virtualCurrency = "virtual_currency"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawStatus = try container.decode(String.self, forKey: .status)
        self.status = Self.decodeStatus(rawStatus, from: container)
    }

    private static func decodeStatus(
        _ rawStatus: String,
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> Status {
        switch rawStatus {
        case "verified":
            return .verified(Self.decodeVerifiedReward(from: container))
        case "pending":
            return .pending
        case "failed":
            return .failed(Self.decodeFailure(from: container))
        default:
            Logger.warn(Strings.backendError.unknown_reward_verification_status(status: rawStatus))
            return .unknown
        }
    }

    private static func decodeFailure(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> Failure {
        // Both fields are best-effort: a malformed/absent value degrades to `nil` rather than
        // failing the decode, so a `failed` status is never lost over a missing reason/message.
        let reason = (try? container.decodeIfPresent(String.self, forKey: .failureReason)) ?? nil
        let message = (try? container.decodeIfPresent(String.self, forKey: .message)) ?? nil
        return Failure(reason: reason, message: message)
    }

    private static func decodeVerifiedReward(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> AdReward {
        guard container.contains(.reward),
              (try? container.decodeNil(forKey: .reward)) != true else {
            return .noReward
        }

        guard let rewardContainer = try? container.nestedContainer(
            keyedBy: RewardCodingKeys.self,
            forKey: .reward
        ) else {
            Logger.warn(Strings.backendError.unexpected_reward_verification_reward_value)
            return .unsupportedReward
        }

        let rewardType = (try? rewardContainer.decode(String.self, forKey: .type)) ?? ""

        switch rewardType {
        case RewardType.virtualCurrency:
            let code = try? rewardContainer.decode(String.self, forKey: .code)
            let amount = try? rewardContainer.decode(Int.self, forKey: .amount)
            guard let code, let amount,
                  let payload = VirtualCurrencyReward(code: code, amount: amount) else {
                Logger.warn(
                    Strings.backendError.malformed_reward_verification_reward_payload(type: rewardType)
                )
                return .unsupportedReward
            }
            return .virtualCurrency(payload)
        default:
            Logger.warn(
                Strings.backendError.unsupported_reward_verification_reward_type(type: rewardType)
            )
            return .unsupportedReward
        }
    }
}

extension RewardVerificationStatusResponse: HTTPResponseBody {

    static func create(with data: Data) throws -> Self {
        return try JSONDecoder.default.decode(Self.self, from: data)
    }
}
