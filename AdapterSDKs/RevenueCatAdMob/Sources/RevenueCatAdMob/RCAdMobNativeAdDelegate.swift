//
//  RCAdMobNativeAdDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobNativeAdDelegate: NSObject, GoogleMobileAds.NativeAdDelegate {

    weak var delegate: GoogleMobileAds.NativeAdDelegate?
    private let rcAdMob: RCAdMob
    private let placement: String?
    private let adUnitID: String

    init(
        rcAdMob: RCAdMob = .shared,
        delegate: GoogleMobileAds.NativeAdDelegate?,
        placement: String?,
        adUnitID: String
    ) {
        self.rcAdMob = rcAdMob
        self.delegate = delegate
        self.placement = placement
        self.adUnitID = adUnitID
    }

    func nativeAdDidRecordImpression(_ nativeAd: GoogleMobileAds.NativeAd) {
        let responseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
        self.rcAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native
        )
        self.delegate?.nativeAdDidRecordImpression?(nativeAd)
    }

    func nativeAdDidRecordClick(_ nativeAd: GoogleMobileAds.NativeAd) {
        let responseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
        self.rcAdMob.trackOpened(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native
        )
        self.delegate?.nativeAdDidRecordClick?(nativeAd)
    }

    func nativeAdWillPresentScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdWillPresentScreen?(nativeAd)
    }

    func nativeAdWillDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdWillDismissScreen?(nativeAd)
    }

    func nativeAdDidDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.delegate?.nativeAdDidDismissScreen?(nativeAd)
    }

}
#endif
