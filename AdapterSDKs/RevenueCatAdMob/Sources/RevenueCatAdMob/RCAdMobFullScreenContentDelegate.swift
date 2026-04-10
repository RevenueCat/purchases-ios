//
//  RCAdMobFullScreenContentDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobFullScreenContentDelegate: NSObject, GoogleMobileAds.FullScreenContentDelegate {

    weak var delegate: GoogleMobileAds.FullScreenContentDelegate?
    private let rcAdMob: RCAdMob
    var placement: String?
    private let adUnitID: String
    private let adFormat: RevenueCat.AdFormat
    private let responseInfoProvider: () -> GoogleMobileAds.ResponseInfo?

    init(
        rcAdMob: RCAdMob = .shared,
        delegate: GoogleMobileAds.FullScreenContentDelegate?,
        placement: String?,
        adUnitID: String,
        adFormat: RevenueCat.AdFormat,
        responseInfoProvider: @escaping () -> GoogleMobileAds.ResponseInfo?
    ) {
        self.rcAdMob = rcAdMob
        self.delegate = delegate
        self.placement = placement
        self.adUnitID = adUnitID
        self.adFormat = adFormat
        self.responseInfoProvider = responseInfoProvider
    }

    func adDidRecordImpression(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        let responseInfo = self.responseInfoProvider()
        self.rcAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: self.adFormat
        )
        self.delegate?.adDidRecordImpression?(presentingAd)
    }

    func adDidRecordClick(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        let responseInfo = self.responseInfoProvider()
        self.rcAdMob.trackOpened(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: self.adFormat
        )
        self.delegate?.adDidRecordClick?(presentingAd)
    }

    func adWillPresentFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adWillPresentFullScreenContent?(presentingAd)
    }

    func adWillDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adWillDismissFullScreenContent?(presentingAd)
    }

    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adDidDismissFullScreenContent?(presentingAd)
    }

    func ad(
        _ presentingAd: any GoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        self.delegate?.ad?(presentingAd, didFailToPresentFullScreenContentWithError: error)
    }

}
#endif
