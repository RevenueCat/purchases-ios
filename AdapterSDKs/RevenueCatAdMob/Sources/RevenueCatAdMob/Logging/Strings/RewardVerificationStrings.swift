//
//  RewardVerificationStrings.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

// swiftlint:disable identifier_name
enum RewardVerificationStrings {

    case setup_purchases_not_configured
    case setup_install(adType: String, transactionID: String)

    case outcome_cancelled(transactionID: String)
    case outcome_suppressed(transactionID: String)

    case result_callback_requires_enable
    case result_callback_missing_verification_state
}

extension RewardVerificationStrings: LogMessage {

    var description: String {
        switch self {
        case .setup_purchases_not_configured:
            return "RevenueCat SDK is not configured. Cannot install reward verification on rewarded ad."
        case let .setup_install(adType, transactionID):
            return "Reward verification install on ad type=\(adType) transactionID=\(transactionID)"

        case let .outcome_cancelled(transactionID):
            return "Reward verification outcome cancelled (task cancelled before delivery) " +
                "transactionID=\(transactionID)"
        case let .outcome_suppressed(transactionID):
            return "Reward verification outcome suppressed (token already consumed) transactionID=\(transactionID)"

        case .result_callback_requires_enable:
            return "Passing a reward verification result callback requires calling enableRewardVerification() " +
                "on this ad after load (with the RevenueCat SDK configured)."
        case .result_callback_missing_verification_state:
            return "Reward verification result callback ignored because reward verification was not enabled " +
                "for this ad. Call `enableRewardVerification()` after loading and before presenting."
        }
    }

    var category: String { return "rewardverification" }
}

#endif
