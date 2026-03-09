//
//  RCAdMobFullScreenContentDelegate.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal final class RCAdMobFullScreenContentDelegate: NSObject, RCGoogleMobileAds.FullScreenContentDelegate {

    weak var delegate: RCGoogleMobileAds.FullScreenContentDelegate?
    private let rcAdMob: RCAdMob
    private let placement: String?
    private let adUnitID: String
    private let adFormat: RevenueCat.AdFormat
    private let responseInfoProvider: () -> RCGoogleMobileAds.ResponseInfo?

    init(
        rcAdMob: RCAdMob = .shared,
        delegate: RCGoogleMobileAds.FullScreenContentDelegate?,
        placement: String?,
        adUnitID: String,
        adFormat: RevenueCat.AdFormat,
        responseInfoProvider: @escaping () -> RCGoogleMobileAds.ResponseInfo?
    ) {
        self.rcAdMob = rcAdMob
        self.delegate = delegate
        self.placement = placement
        self.adUnitID = adUnitID
        self.adFormat = adFormat
        self.responseInfoProvider = responseInfoProvider
    }

    func adDidRecordImpression(_ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd) {
        let responseInfo = self.responseInfoProvider()
        self.rcAdMob.trackDisplayed(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: self.adFormat
        )
        self.delegate?.adDidRecordImpression?(presentingAd)
    }

    func adDidRecordClick(_ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd) {
        let responseInfo = self.responseInfoProvider()
        self.rcAdMob.trackOpened(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: self.adFormat
        )
        self.delegate?.adDidRecordClick?(presentingAd)
    }

    func adWillPresentFullScreenContent(_ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adWillPresentFullScreenContent?(presentingAd)
    }

    func adWillDismissFullScreenContent(_ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adWillDismissFullScreenContent?(presentingAd)
    }

    func adDidDismissFullScreenContent(_ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd) {
        self.delegate?.adDidDismissFullScreenContent?(presentingAd)
    }

    func ad(
        _ presentingAd: any RCGoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        self.delegate?.ad?(presentingAd, didFailToPresentFullScreenContentWithError: error)
    }

}
#endif
