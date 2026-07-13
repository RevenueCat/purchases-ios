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

        /// `moreRewards` contains additional rewards only; it does not repeat `reward`.
        case verified(reward: AdReward, moreRewards: [AdReward])
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
        case failureReason
        case message
        case moreRewards
    }

    private enum RewardCodingKeys: String, CodingKey {
        case type
        case code
        case amount
        case identifier
        case expiresAt
    }

    private enum RewardType {
        static let virtualCurrency = "virtual_currency"
        static let entitlement = "entitlement"
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
            // The backend never sends a null `reward` alongside a non-empty `more_rewards`: the
            // primary reward is always the first grant, so no promotion/normalization is needed.
            return .verified(
                reward: Self.decodePrimaryReward(from: container),
                moreRewards: Self.decodeMoreRewards(from: container)
            )
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
        let reason = try? container.decodeIfPresent(String.self, forKey: .failureReason)
        let message = try? container.decodeIfPresent(String.self, forKey: .message)
        return Failure(reason: reason, message: message)
    }

    private static func decodePrimaryReward(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> AdReward {
        guard container.contains(.reward),
              (try? container.decodeNil(forKey: .reward)) != true else {
            return .noReward
        }

        // `WireReward.init` never throws — it falls back to `.unsupportedReward` internally.
        let wire = try? container.decode(WireReward.self, forKey: .reward)
        return wire?.reward ?? .unsupportedReward
    }

    private static func decodeMoreRewards(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> [AdReward] {
        guard container.contains(.moreRewards),
              (try? container.decodeNil(forKey: .moreRewards)) != true else {
            return []
        }

        guard let wire = try? container.decode([WireReward].self, forKey: .moreRewards) else {
            Logger.warn(Strings.backendError.unexpected_reward_verification_reward_value)
            return []
        }
        return wire.map(\.reward)
    }

    /// Decodes malformed or unknown reward objects as ``AdReward/unsupportedReward``.
    private struct WireReward: Decodable {

        let reward: AdReward

        init(from decoder: Decoder) throws {
            guard let container = try? decoder.container(keyedBy: RewardCodingKeys.self) else {
                Logger.warn(Strings.backendError.unexpected_reward_verification_reward_value)
                self.reward = .unsupportedReward
                return
            }
            self.reward = Self.decodeReward(from: container)
        }

        private static func decodeReward(
            from container: KeyedDecodingContainer<RewardCodingKeys>
        ) -> AdReward {
            let rewardType = (try? container.decode(String.self, forKey: .type)) ?? ""

            switch rewardType {
            case RewardType.virtualCurrency:
                let code = try? container.decode(String.self, forKey: .code)
                let amount = try? container.decode(Int.self, forKey: .amount)
                guard let code, let amount,
                      let payload = VirtualCurrencyReward(code: code, amount: amount) else {
                    Logger.warn(
                        Strings.backendError.malformed_reward_verification_reward_payload(type: rewardType)
                    )
                    return .unsupportedReward
                }
                return .virtualCurrency(payload)
            case RewardType.entitlement:
                let identifier = try? container.decode(String.self, forKey: .identifier)
                let expiresAt = try? container.decode(Date.self, forKey: .expiresAt)
                guard let identifier, let expiresAt,
                      let payload = EntitlementReward(identifier: identifier, expiresAt: expiresAt) else {
                    Logger.warn(
                        Strings.backendError.malformed_reward_verification_reward_payload(type: rewardType)
                    )
                    return .unsupportedReward
                }
                return .entitlement(payload)
            default:
                Logger.warn(
                    Strings.backendError.unsupported_reward_verification_reward_type(type: rewardType)
                )
                return .unsupportedReward
            }
        }
    }
}

extension RewardVerificationStatusResponse: HTTPResponseBody {

    static func create(with data: Data) throws -> Self {
        return try JSONDecoder.default.decode(Self.self, from: data)
    }
}
