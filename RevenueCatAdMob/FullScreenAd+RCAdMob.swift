// swiftlint:disable file_length
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

// MARK: Internal implementation

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.InterstitialAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: RCGoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (RCGoogleMobileAds.InterstitialAd?, Error?) -> Void
    ) {
#if RC_ADMOB_SDK_11
        // swiftlint:disable:next unused_closure_parameter
        RCGoogleMobileAds.InterstitialAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
#else
        // swiftlint:disable:next unused_closure_parameter
        RCGoogleMobileAds.InterstitialAd.load(with: adUnitID, request: request) { loadedAd, error in
#endif
            rcAdMob.handleLoadOutcome(
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

// MARK: Public API

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.InterstitialAd {

    /// Loads an interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.InterstitialAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADInterstitialAd {

    /// Loads an interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADInterstitialAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#endif

// MARK: - AppOpenAd (v11: GADAppOpenAd, v12: AppOpenAd)

// MARK: Internal implementation

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.AppOpenAd {

    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: RCGoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (RCGoogleMobileAds.AppOpenAd?, Error?) -> Void
    ) {
#if RC_ADMOB_SDK_11
        RCGoogleMobileAds.AppOpenAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
#else
        RCGoogleMobileAds.AppOpenAd.load(with: adUnitID, request: request) { loadedAd, error in
#endif
            rcAdMob.handleLoadOutcome(
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

// MARK: Public API

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.AppOpenAd {

    /// Loads an app open ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.AppOpenAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADAppOpenAd {

    /// Loads an app open ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADAppOpenAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#endif

// MARK: - RewardedAd (v11: GADRewardedAd, v12: RewardedAd)

// MARK: Internal implementation

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.RewardedAd {

    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: RCGoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (RCGoogleMobileAds.RewardedAd?, Error?) -> Void
    ) {
#if RC_ADMOB_SDK_11
        RCGoogleMobileAds.RewardedAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
#else
        RCGoogleMobileAds.RewardedAd.load(with: adUnitID, request: request) { loadedAd, error in
#endif
            rcAdMob.handleLoadOutcome(
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

// MARK: Public API

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Loads a rewarded ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.RewardedAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADRewardedAd {

    /// Loads a rewarded ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADRewardedAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#endif

// MARK: - RewardedInterstitialAd (v11: GADRewardedInterstitialAd, v12: RewardedInterstitialAd)

// MARK: Internal implementation

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.RewardedInterstitialAd {

    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: RCGoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: RCGoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (RCGoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
    ) {
#if RC_ADMOB_SDK_11
        RCGoogleMobileAds.RewardedInterstitialAd.load(withAdUnitID: adUnitID, request: request) { loadedAd, error in
#else
        RCGoogleMobileAds.RewardedInterstitialAd.load(with: adUnitID, request: request) { loadedAd, error in
#endif
            rcAdMob.handleLoadOutcome(
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

// MARK: Public API

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Loads a rewarded interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping (GoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADRewardedInterstitialAd {

    /// Loads a rewarded interstitial ad, reports to RevenueCat, and forwards callbacks.
    ///
    /// - Parameters:
    ///   - adUnitID: The ad unit identifier.
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - fullScreenContentDelegate: Optional delegate for full-screen content callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    ///   - completion: Called with the loaded ad or an error.
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GADRequest,
        placement: String?,
        fullScreenContentDelegate: GADFullScreenContentDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil,
        completion: @escaping (GADRewardedInterstitialAd?, Error?) -> Void
    ) {
        self.loadAndTrack(
            withAdUnitID: adUnitID,
            request: request,
            placement: placement,
            fullScreenContentDelegate: fullScreenContentDelegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared,
            completion: completion
        )
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
