//
//  PublicOutcomeMapping.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    static func mapValidatedReward(_ reward: VerifiedReward) -> ValidatedReward {
        switch reward {
        case .virtualCurrency(let item):
            if item.amount > 0 {
                return .virtualCurrency(code: item.code, amount: item.amount)
            }
            return .none
        case .noReward:
            return .none
        case .unsupportedReward:
            return .unknown
        }
    }

    static func mapPublicOutcome(_ outcome: Outcome) -> RewardVerificationOutcome {
        switch outcome {
        case .verified(let reward):
            return .validated(self.mapValidatedReward(reward))
        case .failed:
            return .failed
        }
    }
}

#endif
