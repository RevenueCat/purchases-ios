//
//  AdsInterstitialDelegate.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)

/// Receives lifecycle events from an ``AdsInterstitial``. All methods are optional and called on the main thread.
@available(iOS 15.0, *)
@MainActor
@_spi(Experimental) public protocol AdsInterstitialDelegate: AnyObject {

    /// The ad finished loading and can be presented.
    func interstitialDidLoad(_ interstitial: AdsInterstitial)

    /// Called when loading fails, or when `present(from:)` is called on an ad that is not ready.
    func interstitial(_ interstitial: AdsInterstitial, didFailWithError error: AdsError)

    /// The ad is being presented.
    func interstitialDidPresent(_ interstitial: AdsInterstitial)

    /// The ad recorded an impression.
    func interstitialDidRecordImpression(_ interstitial: AdsInterstitial)

    /// The user clicked the ad.
    func interstitialDidRecordClick(_ interstitial: AdsInterstitial)

    /// The ad was dismissed.
    func interstitialDidDismiss(_ interstitial: AdsInterstitial)

}

// swiftlint:disable missing_docs
/// Default no-op implementations, making every method optional.
@available(iOS 15.0, *)
@_spi(Experimental) public extension AdsInterstitialDelegate {

    func interstitialDidLoad(_ interstitial: AdsInterstitial) {}

    func interstitial(_ interstitial: AdsInterstitial, didFailWithError error: AdsError) {}

    func interstitialDidPresent(_ interstitial: AdsInterstitial) {}

    func interstitialDidRecordImpression(_ interstitial: AdsInterstitial) {}

    func interstitialDidRecordClick(_ interstitial: AdsInterstitial) {}

    func interstitialDidDismiss(_ interstitial: AdsInterstitial) {}

}
// swiftlint:enable missing_docs

#endif
