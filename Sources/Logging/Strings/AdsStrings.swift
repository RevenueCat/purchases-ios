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

    // Terminal failure diagnostics (one is logged when polling ends in `failed`).
    case poll_backend_rejected(reason: String?, message: String?, transactionID: String)
    case poll_exhausted_pending(transactionID: String)
    case poll_exhausted_transient(transactionID: String)
    case poll_unexpected_response(transactionID: String)
    case poll_terminal_error(error: Error, transactionID: String)
    case poll_cancelled(transactionID: String)
    case reward_verification_completed(outcome: String, transactionID: String)
    case reward_verification_virtual_currency_invalidating_cache(transactionID: String)
    case reward_verification_entitlement_invalidating_customer_info(transactionID: String)

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

        case let .poll_backend_rejected(reason, message, transactionID):
            // Prefer the human-readable message; fall back to the raw failure_reason code so the
            // cause still surfaces when the backend sends a reason without a message.
            let detail = message
                ?? reason.map { "the server rejected it (reason: \($0))" }
                ?? "the server rejected it."
            return "Reward verification failed: \(detail) transactionID=\(transactionID)"
        case let .poll_exhausted_pending(transactionID):
            return "Reward verification timed out: the server-side verification (SSV) callback " +
                "was not received in time. Possible causes: SSV is not enabled/configured for this ad " +
                "unit in your ad network's dashboard, the SSV callback URL is misconfigured, the ad " +
                "network delayed delivering the callback, or RevenueCat failed to process the SSV " +
                "webhook. transactionID=\(transactionID)"
        case let .poll_exhausted_transient(transactionID):
            return "Reward verification timed out after repeated transient errors while polling — " +
                "typically unstable device network connectivity. The reward couldn't be verified. " +
                "transactionID=\(transactionID)"
        case let .poll_unexpected_response(transactionID):
            return "Reward verification stopped after the server returned a status this SDK version " +
                "doesn't recognize. Update to the latest SDK version; if you're already on the latest, " +
                "contact RevenueCat support. transactionID=\(transactionID)"
        case let .poll_terminal_error(error, transactionID):
            return "Reward verification stopped after an unrecoverable error: \(error). This is " +
                "unexpected; if it persists, contact RevenueCat support with the error above. " +
                "transactionID=\(transactionID)"
        case let .poll_cancelled(transactionID):
            return "Reward verification was cancelled before completion. transactionID=\(transactionID)"
        case let .reward_verification_completed(outcome, transactionID):
            return "Reward verification completed outcome=\(outcome) transactionID=\(transactionID)"
        case let .reward_verification_virtual_currency_invalidating_cache(transactionID):
            return "Reward verification granted a virtual currency; invalidating virtual currencies cache " +
                "transactionID=\(transactionID)"
        case let .reward_verification_entitlement_invalidating_customer_info(transactionID):
            return "Reward verification granted an entitlement; invalidating CustomerInfo cache " +
                "transactionID=\(transactionID)"
        }
    }

    var category: String { return "ads" }

}
