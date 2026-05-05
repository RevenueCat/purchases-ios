//
//  State.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Per-ad reward-verification correlation data plus a one-shot guard for the reward-time
    /// outcome dispatch.
    @MainActor
    final class State {

        let clientTransactionID: String

        private var didFire = false

        init(clientTransactionID: String) {
            self.clientTransactionID = clientTransactionID
        }

        /// Returns `true` exactly once per instance; subsequent calls return `false`.
        func consumeFireToken() -> Bool {
            guard !self.didFire else { return false }
            self.didFire = true
            return true
        }
    }

    /// Per-ad ``RewardVerification/State`` stash, keyed by the vendor ad object.
    typealias StateStore = AssociatedObjectStore<State>

    @MainActor static let stateStore = StateStore()
}

#endif
