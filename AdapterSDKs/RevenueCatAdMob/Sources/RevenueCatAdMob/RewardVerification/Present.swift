//
//  Present.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat

// MARK: - Internal outcome → presentation result

@available(iOS 15.0, *)
internal extension RewardVerification {

    static func mapVerifiedReward(_ reward: RevenueCat.VerifiedReward) -> RevenueCatAdMob.VerifiedReward {
        switch reward {
        case .virtualCurrency(let item):
            return .virtualCurrency(code: item.code, amount: item.amount)
        case .noReward:
            return .none
        case .unsupportedReward:
            return .unknown
        }
    }

    static func mapOutcome(_ outcome: Outcome) -> RewardVerificationResult {
        switch outcome {
        case .verified(let reward):
            return .verified(self.mapVerifiedReward(reward))
        case .failed:
            return .failed
        }
    }
}

#endif
