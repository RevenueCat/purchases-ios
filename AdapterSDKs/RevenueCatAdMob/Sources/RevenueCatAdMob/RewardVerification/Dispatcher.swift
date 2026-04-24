//
//  Dispatcher.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Drives `Poller` and delivers at most one `Outcome` on the main actor.
    enum Dispatcher {

        /// Awaits the `Poller` outcome, then hops to the main actor to deliver it under the
        /// one-shot guard. If the surrounding `Task` was cancelled, returns without firing so
        /// `state.consumeFireToken()` stays available for a later dispatch.
        static func run(
            clientTransactionID: String,
            state: State,
            poller: Poller,
            outcomeHandler: @escaping @Sendable @MainActor (Outcome) -> Void
        ) async {
            let outcome = await poller.run(clientTransactionID: clientTransactionID)

            // Production never cancels this task, but if a future caller (or a test) does,
            // skip the delivery and preserve the token instead of burning it on `.failed`.
            if Task.isCancelled { return }

            await MainActor.run {
                guard state.consumeFireToken() else { return }
                outcomeHandler(outcome)
            }
        }

        /// Fire-and-forget wrapper around ``run(clientTransactionID:state:poller:outcomeHandler:)``.
        @discardableResult
        static func dispatch(
            clientTransactionID: String,
            state: State,
            poller: Poller,
            outcomeHandler: @escaping @Sendable @MainActor (Outcome) -> Void
        ) -> Task<Void, Never> {
            Task {
                await self.run(
                    clientTransactionID: clientTransactionID,
                    state: state,
                    poller: poller,
                    outcomeHandler: outcomeHandler
                )
            }
        }
    }
}

#endif
