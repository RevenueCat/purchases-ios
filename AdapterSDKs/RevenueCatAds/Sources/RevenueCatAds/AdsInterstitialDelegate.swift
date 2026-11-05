//
//  AdsInterstitialDelegate.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)

/// Receives presentation events from an ``AdsInterstitial``. Load results are reported by ``AdsInterstitial/load()``
/// itself. All methods are optional and called on the main thread.
@available(iOS 15.0, *)
@MainActor
@_spi(Experimental) public protocol AdsInterstitialDelegate: AnyObject {

    /// `present(from:)` was called on an ad that is not ready (``AdsError/Code/notReady``), or from a view
    /// controller that cannot present right now (``AdsError/Code/presentFailed``).
    func interstitial(_ interstitial: AdsInterstitial, didFailToPresentWithError error: AdsError)

    /// The loaded ad expired before being presented. Load again to get a new one.
    func interstitialDidExpire(_ interstitial: AdsInterstitial)

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

    func interstitial(_ interstitial: AdsInterstitial, didFailToPresentWithError error: AdsError) {}

    func interstitialDidExpire(_ interstitial: AdsInterstitial) {}

    func interstitialDidPresent(_ interstitial: AdsInterstitial) {}

    func interstitialDidRecordImpression(_ interstitial: AdsInterstitial) {}

    func interstitialDidRecordClick(_ interstitial: AdsInterstitial) {}

    func interstitialDidDismiss(_ interstitial: AdsInterstitial) {}

}
// swiftlint:enable missing_docs

#endif
