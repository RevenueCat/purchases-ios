//
//  FullScreenAd+RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

// MARK: - InterstitialAd (v11: GADInterstitialAd, v12: InterstitialAd)

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.InterstitialAd {

    /// Loads an interstitial ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.InterstitialAd?, Error?) -> Void
    ) {
        GoogleMobileAds.InterstitialAd.load(with: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.interstitial,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADInterstitialAd {

    /// Loads an interstitial ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADInterstitialAd?, Error?) -> Void
    ) {
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.interstitial,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#endif

// MARK: - AppOpenAd (v11: GADAppOpenAd, v12: AppOpenAd)

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.AppOpenAd {

    /// Loads an app open ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.AppOpenAd?, Error?) -> Void
    ) {
        GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.appOpen,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADAppOpenAd {

    /// Loads an app open ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADAppOpenAd?, Error?) -> Void
    ) {
        GADAppOpenAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.appOpen,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#endif

// MARK: - RewardedAd (v11: GADRewardedAd, v12: RewardedAd)

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Loads a rewarded ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.RewardedAd?, Error?) -> Void
    ) {
        GoogleMobileAds.RewardedAd.load(with: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.rewarded,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADRewardedAd {

    /// Loads a rewarded ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADRewardedAd?, Error?) -> Void
    ) {
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.rewarded,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#endif

// MARK: - RewardedInterstitialAd (v11: GADRewardedInterstitialAd, v12: RewardedInterstitialAd)

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Loads a rewarded interstitial ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
    ) {
        GoogleMobileAds.RewardedInterstitialAd.load(with: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.rewardedInterstitial,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADRewardedInterstitialAd {

    /// Loads a rewarded interstitial ad, reports to RevenueCat; pass a full-screen content delegate for callbacks.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADRewardedInterstitialAd?, Error?) -> Void
    ) {
        GADRewardedInterstitialAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
            RCAdMob.shared.handleLoadOutcome(
                loadedAd: loadedAd,
                error: error,
                context: FullScreenLoadContext(
                    placement: placement,
                    adUnitID: adUnitID,
                    adFormat: RevenueCat.AdFormat.rewardedInterstitial,
                    fullScreenContentDelegate: fullScreenContentDelegate,
                    paidEventHandler: paidEventHandler,
                    responseInfo: loadedAd?.responseInfo
                ),
                completion: completion
            )
        }
    }
}
#endif

@available(iOS 15.0, *)
internal protocol RCFullScreenAdTracking: AnyObject {
    var fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate? { get set }
    var paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)? { get set }
}

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
extension GoogleMobileAds.InterstitialAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.AppOpenAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RCFullScreenAdTracking {}
#else
@available(iOS 15.0, *)
extension GADInterstitialAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GADAppOpenAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GADRewardedAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GADRewardedInterstitialAd: RCFullScreenAdTracking {}
#endif

@available(iOS 15.0, *)
internal struct FullScreenLoadContext {
    let placement: String?
    let adUnitID: String
    let adFormat: RevenueCat.AdFormat
    let fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?
    let paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?
    let responseInfo: RCGoogleMobileAds.ResponseInfo?
}

#endif
