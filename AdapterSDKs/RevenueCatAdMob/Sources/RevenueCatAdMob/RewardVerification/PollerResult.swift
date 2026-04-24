//
//  PollerResult.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Terminal result of a single `Poller.run`. Cancellation is encoded explicitly so callers
    /// don't need a broad catch, and the type system enforces that no other error type can
    /// escape the polling layer.
    enum PollerResult: Equatable, Sendable {
        case outcome(Outcome)
        case cancelled
    }
}

#endif
