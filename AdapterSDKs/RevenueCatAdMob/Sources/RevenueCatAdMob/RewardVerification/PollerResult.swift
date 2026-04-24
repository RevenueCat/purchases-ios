//
//  PollerResult.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Terminal result of a single `Poller.run`: either an `Outcome` (verdict or budget
    /// exhaustion) or `.cancelled` (the underlying task was cancelled).
    enum PollerResult: Equatable, Sendable {
        case outcome(Outcome)
        case cancelled
    }
}

#endif
