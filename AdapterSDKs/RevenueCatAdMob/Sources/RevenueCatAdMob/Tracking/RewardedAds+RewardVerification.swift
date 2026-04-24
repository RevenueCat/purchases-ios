//
//  RewardedAds+RewardVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Configures RevenueCat reward verification for this ad (SSV payload + per-ad state).
    ///
    /// Call after the ad has loaded and before presenting it when you will use reward-verification APIs.
    /// If the RevenueCat SDK is not configured, this method does nothing.
    @MainActor
    func enableRewardVerification() {
        RewardVerification.Setup.install(on: self)
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Configures RevenueCat reward verification for this ad (SSV payload + per-ad state).
    ///
    /// Call after the ad has loaded and before presenting it when you will use reward-verification APIs.
    /// If the RevenueCat SDK is not configured, this method does nothing.
    @MainActor
    func enableRewardVerification() {
        RewardVerification.Setup.install(on: self)
    }
}

#endif
