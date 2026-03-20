//
//  RCAdMobBannerViewDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobBannerViewDelegate: NSObject, GoogleMobileAds.BannerViewDelegate {

    weak var delegate: GoogleMobileAds.BannerViewDelegate?
    private let rcAdMob: RCAdMob
    private let placement: String?

    init(
        rcAdMob: RCAdMob = .shared,
        delegate: GoogleMobileAds.BannerViewDelegate?,
        placement: String?
    ) {
        self.rcAdMob = rcAdMob
        self.delegate = delegate
        self.placement = placement
    }

    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackLoaded(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner
        )
        self.delegate?.bannerViewDidReceiveAd?(bannerView)
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: any Error) {
        self.rcAdMob.trackFailedToLoad(
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner,
            error: error
        )
        self.delegate?.bannerView?(bannerView, didFailToReceiveAdWithError: error)
    }

    func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
        let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner
        )
        self.delegate?.bannerViewDidRecordImpression?(bannerView)
    }

    func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
        let responseInfo: GoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackOpened(
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
#endif
