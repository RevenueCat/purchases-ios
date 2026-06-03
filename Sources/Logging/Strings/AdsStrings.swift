//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdsStrings.swift
//
//  Created by Pol Miro on 27/05/2026.

import Foundation

// swiftlint:disable identifier_name

enum AdsStrings {

    case unknown_reward_kind(rawValue: String)
    case invalid_virtual_currency_payload(code: String?, amount: Int?)
    case reward_verification_token_encoding_failed(error: Error)

    case poll_start(transactionID: String, maxAttempts: Int)
    case poll_attempt(attempt: Int, maxAttempts: Int, transactionID: String)
    case poll_status(status: String, transactionID: String)
    case poll_transient_error(error: Error, transactionID: String)
    case poll_terminal_error(error: Error, transactionID: String)
    case poll_cancelled(transactionID: String)
    case poll_exhausted(maxAttempts: Int, transactionID: String)

}

extension AdsStrings: LogMessage {

    var description: String {
        switch self {
        case let .unknown_reward_kind(rawValue):
            return "Decoded an unknown ad reward kind '\(rawValue)'; falling back to unsupportedReward."
        case let .invalid_virtual_currency_payload(code, amount):
            return "Received an invalid 'virtual_currency' ad reward payload " +
                "(code: \(code ?? "nil"), amount: \(amount.map(String.init) ?? "nil")); " +
                "falling back to unsupportedReward."
        case let .reward_verification_token_encoding_failed(error):
            return "Reward verification token customData encoding failed: \(error)"

        case let .poll_start(transactionID, maxAttempts):
            return "Reward verification poll start transactionID=\(transactionID) maxAttempts=\(maxAttempts)"
        case let .poll_attempt(attempt, maxAttempts, transactionID):
            return "Reward verification poll attempt \(attempt)/\(maxAttempts) transactionID=\(transactionID)"
        case let .poll_status(status, transactionID):
            return "Reward verification poll status=\(status) transactionID=\(transactionID)"
        case let .poll_transient_error(error, transactionID):
            return "Reward verification poll transient error, retrying: \(error) transactionID=\(transactionID)"
        case let .poll_terminal_error(error, transactionID):
            return "Reward verification poll terminal error: \(error) transactionID=\(transactionID)"
        case let .poll_cancelled(transactionID):
            return "Reward verification poll cancelled transactionID=\(transactionID)"
        case let .poll_exhausted(maxAttempts, transactionID):
            return "Reward verification poll exhausted \(maxAttempts) attempts transactionID=\(transactionID)"
        }
    }

    var category: String { return "ads" }

}
