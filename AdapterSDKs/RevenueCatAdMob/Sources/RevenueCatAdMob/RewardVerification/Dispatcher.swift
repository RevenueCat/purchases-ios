//
//  Dispatcher.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) @_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Drives the core reward-verification poll and delivers at most one result on the main actor.
    enum Dispatcher {

        /// Awaits the verification result, then hops to the main actor to deliver it under the
        /// one-shot guard. If the surrounding `Task` was cancelled, returns without firing so
        /// `state.consumeFireToken()` stays available for a later dispatch.
        static func run(
            clientTransactionID: String,
            state: State,
            pollRewardVerification: @Sendable (String) async -> RewardVerificationResult,
            resultHandler: @escaping @Sendable @MainActor (RewardVerificationResult) -> Void
        ) async {
            let result = await pollRewardVerification(clientTransactionID)

            // Production never cancels this task, but if a future caller (or a test) does,
            // skip the delivery and preserve the token instead of burning it.
            await MainActor.run {
                if Task.isCancelled {
                    Logger.debug(RewardVerificationStrings.outcome_cancelled(transactionID: clientTransactionID))
                    return
                }
                guard state.consumeFireToken() else {
                    Logger.debug(RewardVerificationStrings.outcome_suppressed(transactionID: clientTransactionID))
                    return
                }
                resultHandler(result)
            }
        }

        /// Fire-and-forget wrapper around ``run(clientTransactionID:state:pollRewardVerification:resultHandler:)``.
        @discardableResult
        static func dispatch(
            clientTransactionID: String,
            state: State,
            pollRewardVerification: @escaping @Sendable (String) async -> RewardVerificationResult,
            resultHandler: @escaping @Sendable @MainActor (RewardVerificationResult) -> Void
        ) -> Task<Void, Never> {
            Task {
                await self.run(
                    clientTransactionID: clientTransactionID,
                    state: state,
                    pollRewardVerification: pollRewardVerification,
                    resultHandler: resultHandler
                )
            }
        }
    }
}

#endif
