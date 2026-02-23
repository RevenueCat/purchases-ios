//
//  RCAdMobNativeAdDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobNativeAdDelegate: NSObject, RCGoogleMobileAds.NativeAdDelegate {

    weak var delegate: RCGoogleMobileAds.NativeAdDelegate?
    private let placement: String?
    private let adUnitID: String

    init(
        delegate: RCGoogleMobileAds.NativeAdDelegate?,
        placement: String?,
        adUnitID: String
    ) {
        self.delegate = delegate
        self.placement = placement
        self.adUnitID = adUnitID
    }

    func nativeAdDidRecordImpression(_ nativeAd: RCGoogleMobileAds.NativeAd) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
        RCAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native
        )
        self.delegate?.nativeAdDidRecordImpression?(nativeAd)
    }

    func nativeAdDidRecordClick(_ nativeAd: RCGoogleMobileAds.NativeAd) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
        RCAdMob.trackOpened(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native
        )
        self.delegate?.nativeAdDidRecordClick?(nativeAd)
    }

    func nativeAdWillPresentScreen(_ nativeAd: RCGoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdWillPresentScreen?(nativeAd)
    }

    func nativeAdWillDismissScreen(_ nativeAd: RCGoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdWillDismissScreen?(nativeAd)
    }

    func nativeAdDidDismissScreen(_ nativeAd: RCGoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdDidDismissScreen?(nativeAd)
    }

}
#endif
