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
    let verifiedReward: VerifiedReward?

    init(status: Status, verifiedReward: VerifiedReward? = nil) {
        self.status = status
        self.verifiedReward = verifiedReward
    }

    enum Status: String, Codable, Equatable {

        case verified
        case pending
        case failed
        case unknown

    }
}

extension RewardVerificationStatusResponse: Decodable {

    private enum CodingKeys: String, CodingKey {
        case status
        case reward
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
        if let known = Status(rawValue: rawStatus), known != .unknown {
            self.status = known
        } else {
            Logger.warn(Strings.backendError.unknown_reward_verification_status(status: rawStatus))
            self.status = .unknown
        }

        if self.status == .verified {
            self.verifiedReward = Self.decodeVerifiedReward(from: container)
        } else {
            self.verifiedReward = nil
        }
    }

    private static func decodeVerifiedReward(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> VerifiedReward {
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
            guard let code = try? rewardContainer.decode(String.self, forKey: .code),
                  let amount = try? rewardContainer.decode(Int.self, forKey: .amount) else {
                Logger.warn(
                    Strings.backendError.malformed_reward_verification_reward_payload(type: rewardType)
                )
                return .unsupportedReward
            }
            return .virtualCurrency(VirtualCurrencyReward(code: code, amount: amount))
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
