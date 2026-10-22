//
//  AdTracking.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
@_spi(Internal) import RevenueCat

/// Sink for the ad events `RevenueCatAds` reports to RevenueCat's ad-tracking pipeline.
///
/// Nothing else calls `Purchases.shared.adTracker`: production uses ``PurchasesAdTracking``, tests inject fakes.
protocol AdTracking {

    var isConfigured: Bool { get }

    func trackAdLoaded(_ data: AdLoaded)
    func trackAdDisplayed(_ data: AdDisplayed)
    func trackAdOpened(_ data: AdOpened)
    func trackAdRevenue(_ data: AdRevenue)
    func trackAdFailedToLoad(_ data: AdFailedToLoad)

}

final class PurchasesAdTracking: AdTracking {

    var isConfigured: Bool { Purchases.isConfigured }

    func trackAdLoaded(_ data: AdLoaded) {
        Purchases.shared.adTracker.trackAdLoaded(data, captureMethod: .iosRevenueCatAds)
    }

    func trackAdDisplayed(_ data: AdDisplayed) {
        Purchases.shared.adTracker.trackAdDisplayed(data, captureMethod: .iosRevenueCatAds)
    }

    func trackAdOpened(_ data: AdOpened) {
        Purchases.shared.adTracker.trackAdOpened(data, captureMethod: .iosRevenueCatAds)
    }

    func trackAdRevenue(_ data: AdRevenue) {
        Purchases.shared.adTracker.trackAdRevenue(data, captureMethod: .iosRevenueCatAds)
    }

    func trackAdFailedToLoad(_ data: AdFailedToLoad) {
        Purchases.shared.adTracker.trackAdFailedToLoad(data, captureMethod: .iosRevenueCatAds)
    }

}

#endif
