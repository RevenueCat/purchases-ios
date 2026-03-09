//
//  RCAdMobBannerViewDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobBannerViewDelegate: NSObject, RCGoogleMobileAds.BannerViewDelegate {

    weak var delegate: RCGoogleMobileAds.BannerViewDelegate?
    private let rcAdMob: RCAdMob
    private let placement: String?

    init(
        rcAdMob: RCAdMob = .shared,
        delegate: RCGoogleMobileAds.BannerViewDelegate?,
        placement: String?
    ) {
        self.rcAdMob = rcAdMob
        self.delegate = delegate
        self.placement = placement
    }

    func bannerViewDidReceiveAd(_ bannerView: RCGoogleMobileAds.BannerView) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackLoaded(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner
        )
        self.delegate?.bannerViewDidReceiveAd?(bannerView)
    }

    func bannerView(_ bannerView: RCGoogleMobileAds.BannerView, didFailToReceiveAdWithError error: any Error) {
        self.rcAdMob.trackFailedToLoad(
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner,
            error: error
        )
        self.delegate?.bannerView?(bannerView, didFailToReceiveAdWithError: error)
    }

    func bannerViewDidRecordImpression(_ bannerView: RCGoogleMobileAds.BannerView) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner
        )
        self.delegate?.bannerViewDidRecordImpression?(bannerView)
    }

    func bannerViewDidRecordClick(_ bannerView: RCGoogleMobileAds.BannerView) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = bannerView.responseInfo
        self.rcAdMob.trackOpened(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: bannerView.adUnitID,
            adFormat: RevenueCat.AdFormat.banner
        )
        self.delegate?.bannerViewDidRecordClick?(bannerView)
    }

    func bannerViewWillPresentScreen(_ bannerView: RCGoogleMobileAds.BannerView) {
        self.delegate?.bannerViewWillPresentScreen?(bannerView)
    }

    func bannerViewWillDismissScreen(_ bannerView: RCGoogleMobileAds.BannerView) {
        self.delegate?.bannerViewWillDismissScreen?(bannerView)
    }

    func bannerViewDidDismissScreen(_ bannerView: RCGoogleMobileAds.BannerView) {
        self.delegate?.bannerViewDidDismissScreen?(bannerView)
    }

}
#endif
