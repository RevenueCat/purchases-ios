//
//  FullScreenAd+RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

// MARK: - InterstitialAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.InterstitialAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (GoogleMobileAds.InterstitialAd?, Error?) -> Void
    ) {
        Self.load(with: adUnitID, request: request) { loadedAd, error in
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

// MARK: - AppOpenAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.AppOpenAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (GoogleMobileAds.AppOpenAd?, Error?) -> Void
    ) {
        Self.load(with: adUnitID, request: request) { loadedAd, error in
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

// MARK: - RewardedAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.RewardedAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (GoogleMobileAds.RewardedAd?, Error?) -> Void
    ) {
        Self.load(with: adUnitID, request: request) { loadedAd, error in
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

// MARK: - RewardedInterstitialAd

@available(iOS 15.0, *)
internal extension GoogleMobileAds.RewardedInterstitialAd {

    // swiftlint:disable:next function_parameter_count
    static func loadAndTrack(
        withAdUnitID adUnitID: String,
        request: GoogleMobileAds.Request,
        placement: String?,
        fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob,
        completion: @escaping (GoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
    ) {
        Self.load(with: adUnitID, request: request) { loadedAd, error in
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

@available(iOS 15.0, *)
internal protocol RCFullScreenAdTracking: AnyObject {
    var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate? { get set }
    var paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? { get set }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.InterstitialAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.AppOpenAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RCFullScreenAdTracking {}
@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RCFullScreenAdTracking {}

@available(iOS 15.0, *)
internal struct FullScreenLoadContext {
    let placement: String?
    let adUnitID: String
    let adFormat: RevenueCat.AdFormat
    let fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
    let paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?
    let responseInfo: GoogleMobileAds.ResponseInfo?
}

#endif
