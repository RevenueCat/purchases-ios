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

/// Decoded body of
/// `GET /v1/subscribers/{app_user_id}/ads/reward_verifications/{client_transaction_id}`.
///
/// The endpoint returns 200 with a `status` of `verified`, `pending`, or `failed`.
/// Unrecognized future values decode to `.unknown` so the caller can choose how to
/// handle them rather than failing decode.
struct RewardVerificationStatusResponse: Equatable {

    let status: Status

    enum Status: String, Codable, Equatable {

        case verified
        case pending
        case failed
        case unknown

    }
}

extension RewardVerificationStatusResponse: Codable {

    private enum CodingKeys: String, CodingKey {
        case status
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
    }
}

extension RewardVerificationStatusResponse: HTTPResponseBody {

    static func create(with data: Data) throws -> Self {
        return try JSONDecoder.default.decode(Self.self, from: data)
    }
}
