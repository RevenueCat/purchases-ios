//
//  NativeAdDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// `GoogleMobileAds.NativeAdDelegate` wrapper that forwards events to the user's delegate
    /// while reporting display, click, and revenue events for native ads to the adapter.
    final class NativeAdDelegate: NSObject, GoogleMobileAds.NativeAdDelegate {

        weak var delegate: GoogleMobileAds.NativeAdDelegate?
        private let adapter: Tracking.Adapter
        private let placement: String?
        private let adUnitID: String

        init(
            adapter: Tracking.Adapter = .shared,
            delegate: GoogleMobileAds.NativeAdDelegate?,
            placement: String?,
            adUnitID: String
        ) {
            self.adapter = adapter
            self.delegate = delegate
            self.placement = placement
            self.adUnitID = adUnitID
        }

        func nativeAdDidRecordImpression(_ nativeAd: GoogleMobileAds.NativeAd) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
            self.adapter.trackDisplayed(
                responseInfo: responseInfo,
                placement: self.placement,
                adUnitID: self.adUnitID,
                adFormat: RevenueCat.AdFormat.native
            )
            self.delegate?.nativeAdDidRecordImpression?(nativeAd)
        }

        func nativeAdDidRecordClick(_ nativeAd: GoogleMobileAds.NativeAd) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
            self.adapter.trackOpened(
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

}
#endif
