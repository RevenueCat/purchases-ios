//
//  BannerViewDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// `GoogleMobileAds.BannerViewDelegate` wrapper that forwards events to the user's delegate
    /// while reporting load, display, click, and failure events to the adapter.
    final class BannerViewDelegate: NSObject, GoogleMobileAds.BannerViewDelegate {

        weak var delegate: GoogleMobileAds.BannerViewDelegate?
        private let adapter: Tracking.Adapter
        private let placement: String?

        init(
            adapter: Tracking.Adapter = .shared,
            delegate: GoogleMobileAds.BannerViewDelegate?,
            placement: String?
        ) {
            self.adapter = adapter
            self.delegate = delegate
            self.placement = placement
        }

        func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
            self.adapter.trackLoaded(
                responseInfo: responseInfo,
                placement: self.placement,
                adUnitID: bannerView.adUnitID,
                adFormat: RevenueCat.AdFormat.banner
            )
            self.delegate?.bannerViewDidReceiveAd?(bannerView)
        }

        func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: any Error) {
            self.adapter.trackFailedToLoad(
                placement: self.placement,
                adUnitID: bannerView.adUnitID,
                adFormat: RevenueCat.AdFormat.banner,
                error: error
            )
            self.delegate?.bannerView?(bannerView, didFailToReceiveAdWithError: error)
        }

        func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
            self.adapter.trackDisplayed(
                responseInfo: responseInfo,
                placement: self.placement,
                adUnitID: bannerView.adUnitID,
                adFormat: RevenueCat.AdFormat.banner
            )
            self.delegate?.bannerViewDidRecordImpression?(bannerView)
        }

        func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
            self.adapter.trackOpened(
                responseInfo: responseInfo,
                placement: self.placement,
                adUnitID: bannerView.adUnitID,
                adFormat: RevenueCat.AdFormat.banner
            )
            self.delegate?.bannerViewDidRecordClick?(bannerView)
        }

        func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            self.delegate?.bannerViewWillPresentScreen?(bannerView)
        }

        func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            self.delegate?.bannerViewWillDismissScreen?(bannerView)
        }

        func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            self.delegate?.bannerViewDidDismissScreen?(bannerView)
        }

    }

}
#endif
