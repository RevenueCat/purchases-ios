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
    final class State: @unchecked Sendable {

        let clientTransactionID: String

        private let lock = NSLock()
        private var didFire = false

        init(clientTransactionID: String) {
            self.clientTransactionID = clientTransactionID
        }

        /// Returns `true` exactly once per instance; subsequent calls return `false`. Atomic.
        func consumeFireToken() -> Bool {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.didFire else { return false }
            self.didFire = true
            return true
        }
    }
}

#endif
