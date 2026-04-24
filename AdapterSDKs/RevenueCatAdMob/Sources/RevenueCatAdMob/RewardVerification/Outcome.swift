//
//  Outcome.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Terminal SSV verdict delivered by `Dispatcher`.
    enum Outcome: @unchecked Sendable {
        case verified(VerifiedReward)
        case failed
    }
}

#endif
