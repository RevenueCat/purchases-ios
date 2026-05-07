//
//  RewardVerificationStrings.swift
//
//  Created by RevenueCat.
//

import Foundation
@_spi(Internal) import RevenueCat

// swiftlint:disable identifier_name
enum RewardVerificationStrings {

    case setup_purchases_not_configured
    case setup_install(adType: String, transactionID: String)
    case setup_custom_reward_text_encoding_failed(error: Error)

    case poll_start(transactionID: String, maxAttempts: Int)
    case poll_attempt(attempt: Int, maxAttempts: Int, transactionID: String)
    case poll_status(status: String, transactionID: String)
    case poll_transient_error(error: Error, transactionID: String)
    case poll_terminal_error(error: Error, transactionID: String)
    case poll_cancelled(transactionID: String)
    case poll_exhausted(maxAttempts: Int, transactionID: String)

    case outcome_delivered(outcome: String, transactionID: String)
    case outcome_suppressed(transactionID: String)
}

extension RewardVerificationStrings: LogMessage {

    var description: String {
        switch self {
        case .setup_purchases_not_configured:
            return "RevenueCat SDK is not configured. Cannot install SSV on rewarded ad."
        case let .setup_install(adType, transactionID):
            return "SSV install on ad type=\(adType) transactionID=\(transactionID)"
        case let .setup_custom_reward_text_encoding_failed(error):
            return "customRewardText encoding failed: \(error)"

        case let .poll_start(transactionID, maxAttempts):
            return "SSV poll start transactionID=\(transactionID) maxAttempts=\(maxAttempts)"
        case let .poll_attempt(attempt, maxAttempts, transactionID):
            return "SSV poll attempt \(attempt)/\(maxAttempts) transactionID=\(transactionID)"
        case let .poll_status(status, transactionID):
            return "SSV poll status=\(status) transactionID=\(transactionID)"
        case let .poll_transient_error(error, transactionID):
            return "SSV poll transient error, retrying: \(error) transactionID=\(transactionID)"
        case let .poll_terminal_error(error, transactionID):
            return "SSV poll terminal error: \(error) transactionID=\(transactionID)"
        case let .poll_cancelled(transactionID):
            return "SSV poll cancelled transactionID=\(transactionID)"
        case let .poll_exhausted(maxAttempts, transactionID):
            return "SSV poll exhausted \(maxAttempts) attempts transactionID=\(transactionID)"

        case let .outcome_delivered(outcome, transactionID):
            return "SSV outcome \(outcome) transactionID=\(transactionID)"
        case let .outcome_suppressed(transactionID):
            return "SSV outcome suppressed (token already consumed) transactionID=\(transactionID)"
        }
    }

    var category: String { return "rewardverification" }
}
