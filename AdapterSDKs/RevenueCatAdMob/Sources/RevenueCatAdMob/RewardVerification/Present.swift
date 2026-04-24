//
//  Present.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Wires optional reward-verification callbacks around Google’s `present`.
    enum Present {

        /// - Parameter poller: For unit tests; pass `nil` in production to use ``Poller/makeDefault()``.
        @MainActor
        static func present(
            capableAd: some CapableAd,
            rewardVerificationStarted: (() -> Void)?,
            rewardVerificationResult: ((RewardVerificationResult) -> Void)?,
            poller: Poller? = nil,
            performPresent: @MainActor (@escaping () -> Void) -> Void
        ) {
            if rewardVerificationResult != nil {
                precondition(
                    Setup.verificationState(for: capableAd) != nil,
                    Strings.rewardVerificationResultRequiresEnable
                )
            }

            guard let state = Setup.verificationState(for: capableAd) else {
                performPresent { rewardVerificationStarted?() }
                return
            }

            guard let onResult = rewardVerificationResult else {
                performPresent { rewardVerificationStarted?() }
                return
            }

            let resolvedPoller = poller ?? Poller.makeDefault()

            performPresent {
                rewardVerificationStarted?()
                Dispatcher.dispatch(
                    clientTransactionID: state.clientTransactionID,
                    state: state,
                    poller: resolvedPoller,
                    outcomeHandler: { internalOutcome in
                        onResult(RewardVerification.mapOutcome(internalOutcome))
                    }
                )
            }
        }
    }
}

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
