//
//  RCAdMobCompatibility.swift
//
//  Unifies AdMob SDK v11 (GAD-prefixed) and v12+ (Swift API renames). Default is v12+.
//  Set RC_ADMOB_SDK_11 only when using Google Mobile Ads SDK v11.x.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds

// MARK: - RCGoogleMobileAds namespace (v11 vs v12+)

internal enum RCGoogleMobileAds {

#if RC_ADMOB_SDK_11
    typealias Request = GADRequest
    typealias ResponseInfo = GADResponseInfo
    typealias AdValue = GADAdValue
    typealias AdValuePrecision = GADAdValuePrecision
    typealias InterstitialAd = GADInterstitialAd
    typealias AppOpenAd = GADAppOpenAd
    typealias RewardedAd = GADRewardedAd
    typealias RewardedInterstitialAd = GADRewardedInterstitialAd
    typealias FullScreenContentDelegate = GADFullScreenContentDelegate
    typealias FullScreenPresentingAd = GADFullScreenPresentingAd
    typealias BannerView = GADBannerView
    typealias BannerViewDelegate = GADBannerViewDelegate
    typealias AdLoader = GADAdLoader
    typealias AdLoaderOptions = GADAdLoaderOptions
    typealias NativeAd = GADNativeAd
    typealias NativeAdDelegate = GADNativeAdDelegate
    typealias NativeAdLoaderDelegate = GADNativeAdLoaderDelegate
    typealias AdLoaderDelegate = GADAdLoaderDelegate
#else
    typealias Request = GoogleMobileAds.Request
    typealias ResponseInfo = GoogleMobileAds.ResponseInfo
    typealias AdValue = GoogleMobileAds.AdValue
    typealias AdValuePrecision = GoogleMobileAds.AdValuePrecision
    typealias InterstitialAd = GoogleMobileAds.InterstitialAd
    typealias AppOpenAd = GoogleMobileAds.AppOpenAd
    typealias RewardedAd = GoogleMobileAds.RewardedAd
    typealias RewardedInterstitialAd = GoogleMobileAds.RewardedInterstitialAd
    typealias FullScreenContentDelegate = GoogleMobileAds.FullScreenContentDelegate
    typealias FullScreenPresentingAd = GoogleMobileAds.FullScreenPresentingAd
    typealias BannerView = GoogleMobileAds.BannerView
    typealias BannerViewDelegate = GoogleMobileAds.BannerViewDelegate
    typealias AdLoader = GoogleMobileAds.AdLoader
    typealias NativeAd = GoogleMobileAds.NativeAd
    typealias NativeAdDelegate = GoogleMobileAds.NativeAdDelegate
    typealias NativeAdLoaderDelegate = GoogleMobileAds.NativeAdLoaderDelegate
    typealias AdLoaderDelegate = GoogleMobileAds.AdLoaderDelegate
#endif

}

#endif
