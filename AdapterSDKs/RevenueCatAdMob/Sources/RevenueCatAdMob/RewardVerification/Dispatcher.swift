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

    /// Runs the polling loop, hops to the main actor, and fires the outcome handler at most once
    /// per ad. Cancellation here means "caller asked to stop": deliver nothing, leave the
    /// one-shot token intact so a later dispatch on the same `State` can still fire.
    enum Dispatcher {

        /// Drives the Poller and delivers exactly one `Outcome` on the main actor — unless the
        /// task is cancelled before the Poller produces an outcome, in which case nothing is
        /// delivered and `state.consumeFireToken()` is preserved for any later dispatch.
        ///
        /// Once the Poller returns an outcome, delivery is unconditional: there is no
        /// `Task.checkCancellation()` between the Poller and the `MainActor` hop, because
        /// at-most-once delivery wins over respecting late cancellation.
        static func run(
            clientTransactionID: String,
            state: State,
            poller: Poller,
            outcomeHandler: @escaping @Sendable @MainActor (Outcome) -> Void
        ) async {
            switch await poller.run(clientTransactionID: clientTransactionID) {
            case .cancelled:
                return
            case .outcome(let outcome):
                await MainActor.run {
                    guard state.consumeFireToken() else { return }
                    outcomeHandler(outcome)
                }
            }
        }

        /// Fire-and-forget wrapper. Returns the spawned `Task`; cancelling that handle propagates
        /// to the Poller's `Task.sleep` (and to any cooperative cancellation in the poll request),
        /// causing `run` to return without delivering an outcome.
        ///
        /// Cancellation contract: cancelling the returned task before the Poller produces an
        /// outcome means *no outcome is delivered* and `state.consumeFireToken()` stays unused —
        /// a later `dispatch` on the same `State` can still fire. Once the Poller has produced
        /// an outcome, delivery is unconditional.
        ///
        /// Note: `Task { }` is unstructured, so parent-task cancellation does NOT propagate
        /// automatically — callers must retain and `.cancel()` the returned handle to abort.
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
