//
//  RCGoogleMobileAds.NativeAdLoader.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

private enum RCNativeAdLoaderAssociatedKeys {
    static var trackingProxy: UInt8 = 0
}

// MARK: - Internal implementation (shared across SDK versions)

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.AdLoader {

    func loadAndTrack(
        _ request: RCGoogleMobileAds.Request,
        placement: String?,
        nativeAdDelegate: (any RCGoogleMobileAds.NativeAdDelegate)?,
        rcAdMob: RCAdMob
    ) {
        let previousDelegate = (self.delegate as? RCNativeAdLoaderDelegateProxy)?
            .forwardedLoaderDelegate ?? self.delegate

        let proxy = RCNativeAdLoaderDelegateProxy(
            rcAdMob: rcAdMob,
            adUnitID: self.adUnitID,
            placement: placement,
            delegate: previousDelegate,
            nativeAdDelegate: nativeAdDelegate
        )
        objc_setAssociatedObject(
            self,
            &RCNativeAdLoaderAssociatedKeys.trackingProxy,
            proxy,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        self.delegate = proxy
        self.load(request)
    }

}

// MARK: - Public API

#if !RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.AdLoader {

    /// Loads a native ad request, tracks lifecycle events with RevenueCat, and forwards callbacks.
    ///
    /// Uses this loader's own `adUnitID` for tracking to guarantee consistency.
    ///
    /// - Parameters:
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - nativeAdDelegate: Optional delegate that will receive native ad callbacks.
    func loadAndTrack(
        _ request: GoogleMobileAds.Request,
        placement: String? = nil,
        nativeAdDelegate: (any GoogleMobileAds.NativeAdDelegate)? = nil
    ) {
        self.loadAndTrack(
            request,
            placement: placement,
            nativeAdDelegate: nativeAdDelegate,
            rcAdMob: .shared
        )
    }
}
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADAdLoader {

    /// Loads a native ad request, tracks lifecycle events with RevenueCat, and forwards callbacks.
    ///
    /// Uses this loader's own `adUnitID` for tracking to guarantee consistency.
    ///
    /// - Parameters:
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - nativeAdDelegate: Optional delegate that will receive native ad callbacks.
    func loadAndTrack(
        _ request: GADRequest,
        placement: String? = nil,
        nativeAdDelegate: GADNativeAdDelegate? = nil
    ) {
        self.loadAndTrack(
            request,
            placement: placement,
            nativeAdDelegate: nativeAdDelegate,
            rcAdMob: .shared
        )
    }
}
#endif

@available(iOS 15.0, *)
private final class RCNativeAdLoaderDelegateProxy: NSObject,
    RCGoogleMobileAds.NativeAdLoaderDelegate,
    RCGoogleMobileAds.AdLoaderDelegate {

    private let rcAdMob: RCAdMob
    private let adUnitID: String
    private let placement: String?
    private weak var loaderDelegate: RCGoogleMobileAds.AdLoaderDelegate?
    private weak var nativeLoaderDelegate: RCGoogleMobileAds.NativeAdLoaderDelegate?
    private weak var nativeAdDelegate: RCGoogleMobileAds.NativeAdDelegate?

    init(
        rcAdMob: RCAdMob = .shared,
        adUnitID: String,
        placement: String?,
        delegate: RCGoogleMobileAds.AdLoaderDelegate?,
        nativeAdDelegate: RCGoogleMobileAds.NativeAdDelegate?
    ) {
        self.rcAdMob = rcAdMob
        self.adUnitID = adUnitID
        self.placement = placement
        self.loaderDelegate = delegate
        self.nativeLoaderDelegate = delegate as? RCGoogleMobileAds.NativeAdLoaderDelegate
        self.nativeAdDelegate = nativeAdDelegate
    }

    var forwardedLoaderDelegate: RCGoogleMobileAds.AdLoaderDelegate? {
        self.loaderDelegate
    }

    func adLoader(_ adLoader: RCGoogleMobileAds.AdLoader, didReceive nativeAd: RCGoogleMobileAds.NativeAd) {
        let responseInfo: RCGoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
        self.rcAdMob.trackLoaded(
            responseInfo: responseInfo,
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native
        )

        let existingDelegate = self.nativeAdDelegate ?? nativeAd.delegate
        let trackingDelegate = RCAdMobNativeAdDelegate(
            rcAdMob: self.rcAdMob,
            delegate: existingDelegate,
            placement: self.placement,
            adUnitID: self.adUnitID
        )
        self.rcAdMob.retainNativeDelegate(trackingDelegate, for: nativeAd)
        nativeAd.delegate = trackingDelegate

        let rcAdMob = self.rcAdMob
        let placement = self.placement
        let adUnitID = self.adUnitID
        let existingPaidHandler = nativeAd.paidEventHandler
        nativeAd.paidEventHandler = { [weak nativeAd] adValue in
            guard let nativeAd else {
                existingPaidHandler?(adValue)
                return
            }
            let paidResponseInfo: RCGoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
            rcAdMob.trackRevenue(
                placement: placement,
                adUnitID: adUnitID,
                adFormat: RevenueCat.AdFormat.native,
                responseInfo: paidResponseInfo,
                adValue: adValue
            )
            existingPaidHandler?(adValue)
        }

        self.nativeLoaderDelegate?.adLoader(adLoader, didReceive: nativeAd)
    }

    func adLoader(_ adLoader: RCGoogleMobileAds.AdLoader, didFailToReceiveAdWithError error: Error) {
        self.rcAdMob.trackFailedToLoad(
            placement: self.placement,
            adUnitID: self.adUnitID,
            adFormat: RevenueCat.AdFormat.native,
            error: error
        )
        self.loaderDelegate?.adLoader(adLoader, didFailToReceiveAdWithError: error)
    }

    func adLoaderDidFinishLoading(_ adLoader: RCGoogleMobileAds.AdLoader) {
        self.loaderDelegate?.adLoaderDidFinishLoading?(adLoader)
    }

}

#endif
