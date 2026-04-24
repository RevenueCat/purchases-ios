//
//  Present.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Wires optional reward-verification callbacks around Google’s `present`.
    enum Present {

        /// - Parameter poller: For unit tests; pass `nil` in production to use ``Poller/makeDefault()``.
        @MainActor
        static func present(
            capableAd: some CapableAd,
            rewardVerificationStarted: (() -> Void)?,
            rewardVerificationOutcome: ((RewardVerificationOutcome) -> Void)?,
            poller: Poller? = nil,
            performPresent: @MainActor (@escaping () -> Void) -> Void
        ) {
            if rewardVerificationOutcome != nil {
                precondition(
                    Setup.verificationState(for: capableAd) != nil,
                    Strings.rewardVerificationOutcomeRequiresEnable
                )
            }

            guard let state = Setup.verificationState(for: capableAd) else {
                performPresent { rewardVerificationStarted?() }
                return
            }

            guard let onOutcome = rewardVerificationOutcome else {
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
                        onOutcome(RewardVerification.mapPublicOutcome(internalOutcome))
                    }
                )
            }
        }
    }
}

#endif
