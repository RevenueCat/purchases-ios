//
//  Tracker.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// Sink for AdMob lifecycle events the adapter forwards to RevenueCat's ad-tracking pipeline.
    ///
    /// The adapter never calls `Purchases.shared.adTracker` directly; everything is routed through
    /// a `Tracking.Tracker`. The production conformance is `Tracking.PurchasesTracker`; tests inject
    /// fakes.
    protocol Tracker {
        var isConfigured: Bool { get }
        func trackAdLoaded(_ data: AdLoaded)
        func trackAdDisplayed(_ data: AdDisplayed)
        func trackAdOpened(_ data: AdOpened)
        func trackAdRevenue(_ data: AdRevenue)
        func trackAdFailedToLoad(_ data: AdFailedToLoad)
    }

}

#endif
