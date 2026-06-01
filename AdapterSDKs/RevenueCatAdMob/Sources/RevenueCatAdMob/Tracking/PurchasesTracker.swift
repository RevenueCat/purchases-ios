//
//  PurchasesTracker.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) @_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// Production `Tracking.Tracker` that forwards events to `Purchases.shared.adTracker`.
    final class PurchasesTracker: Tracker {

        var isConfigured: Bool { Purchases.isConfigured }

        func trackAdLoaded(_ data: AdLoaded) { Purchases.shared.adTracker.trackAdLoaded(data) }
        func trackAdDisplayed(_ data: AdDisplayed) { Purchases.shared.adTracker.trackAdDisplayed(data) }
        func trackAdOpened(_ data: AdOpened) { Purchases.shared.adTracker.trackAdOpened(data) }
        func trackAdRevenue(_ data: AdRevenue) { Purchases.shared.adTracker.trackAdRevenue(data) }
        func trackAdFailedToLoad(_ data: AdFailedToLoad) { Purchases.shared.adTracker.trackAdFailedToLoad(data) }
        func trackAdRewardEarnedUnverified(_ data: AdRewardEarnedUnverified) {
            Purchases.shared.adTracker.trackAdRewardEarnedUnverified(data)
        }
        func trackAdRewardVerified(_ data: AdRewardVerified) {
            Purchases.shared.adTracker.trackAdRewardVerified(data)
        }
        func trackAdRewardFailedToVerify(_ data: AdRewardFailedToVerify) {
            Purchases.shared.adTracker.trackAdRewardFailedToVerify(data)
        }

    }

}

#endif
