//
//  Outcome.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) @_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Terminal SSV verdict delivered by `Dispatcher`.
    enum Outcome: Sendable {
        case verified(RevenueCat.AdReward)
        case failed(FailureReason)
    }

    /// Internal classification of why verification failed.
    enum FailureReason: Sendable, Equatable {
        case timeout
        case backendError
        case unknown
    }
}

#endif
