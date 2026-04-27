//
//  FullScreenAd+RCAdMob+Completion.swift
//
//  Created by RevenueCat on 4/10/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

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
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping @MainActor (GoogleMobileAds.InterstitialAd?, Error?) -> Void
    ) {
        asyncToCompletion({
            try await self.loadAndTrack(
                withAdUnitID: adUnitID,
                request: request,
                placement: placement,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        }, completion: completion)
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
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping @MainActor (GoogleMobileAds.AppOpenAd?, Error?) -> Void
    ) {
        asyncToCompletion({
            try await self.loadAndTrack(
                withAdUnitID: adUnitID,
                request: request,
                placement: placement,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        }, completion: completion)
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
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping @MainActor (GoogleMobileAds.RewardedAd?, Error?) -> Void
    ) {
        asyncToCompletion({
            try await self.loadAndTrack(
                withAdUnitID: adUnitID,
                request: request,
                placement: placement,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        }, completion: completion)
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
        placement: String? = nil,
        fullScreenContentDelegate: (any GoogleMobileAds.FullScreenContentDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil,
        completion: @escaping @MainActor (GoogleMobileAds.RewardedInterstitialAd?, Error?) -> Void
    ) {
        asyncToCompletion({
            try await self.loadAndTrack(
                withAdUnitID: adUnitID,
                request: request,
                placement: placement,
                fullScreenContentDelegate: fullScreenContentDelegate,
                paidEventHandler: paidEventHandler
            )
        }, completion: completion)
    }
}

/// Bridges an `async throws` call to a `@MainActor` completion handler.
internal func asyncToCompletion<T>(
    _ method: @escaping () async throws -> T,
    completion: @escaping @MainActor (T?, Error?) -> Void
) {
    Task {
        do {
            let result = try await method()
            await completion(result, nil)
        } catch {
            await completion(nil, error)
        }
    }
}

#endif
