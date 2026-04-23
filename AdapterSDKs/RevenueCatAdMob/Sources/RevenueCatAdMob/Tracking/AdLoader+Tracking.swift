//
//  AdLoader+Tracking.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

private enum NativeAdLoaderAssociatedKeys {
    static var trackingProxy: UInt8 = 0
}

@available(iOS 15.0, *)
internal extension GoogleMobileAds.AdLoader {

    func loadAndTrack(
        _ request: GoogleMobileAds.Request,
        placement: String?,
        nativeAdDelegate: (any GoogleMobileAds.NativeAdDelegate)?,
        adapter: Tracking.Adapter
    ) {
        let previousDelegate = (self.delegate as? Tracking.NativeAdLoaderDelegateProxy)?
            .forwardedLoaderDelegate ?? self.delegate

        let proxy = Tracking.NativeAdLoaderDelegateProxy(
            adapter: adapter,
            adUnitID: self.adUnitID,
            placement: placement,
            delegate: previousDelegate,
            nativeAdDelegate: nativeAdDelegate
        )
        objc_setAssociatedObject(
            self,
            &NativeAdLoaderAssociatedKeys.trackingProxy,
            proxy,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        self.delegate = proxy
        self.load(request)
    }

}

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
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    func loadAndTrack(
        _ request: GoogleMobileAds.Request,
        placement: String? = nil,
        nativeAdDelegate: (any GoogleMobileAds.NativeAdDelegate)? = nil
    ) {
        self.loadAndTrack(
            request,
            placement: placement,
            nativeAdDelegate: nativeAdDelegate,
            adapter: .shared
        )
    }
}

@available(iOS 15.0, *)
internal extension Tracking {

    /// Proxy that intercepts `GoogleMobileAds.NativeAdLoaderDelegate` and `AdLoaderDelegate`
    /// callbacks for an `AdLoader`, reports them to the adapter, installs a tracking
    /// `NativeAdDelegate` on the loaded ad, wraps the paid-event handler, and then
    /// forwards everything to the caller's original delegate.
    final class NativeAdLoaderDelegateProxy: NSObject,
        GoogleMobileAds.NativeAdLoaderDelegate,
        GoogleMobileAds.AdLoaderDelegate {

        private let adapter: Tracking.Adapter
        private let adUnitID: String
        private let placement: String?
        private weak var loaderDelegate: GoogleMobileAds.AdLoaderDelegate?
        private weak var nativeLoaderDelegate: GoogleMobileAds.NativeAdLoaderDelegate?
        private weak var nativeAdDelegate: GoogleMobileAds.NativeAdDelegate?

        init(
            adapter: Tracking.Adapter = .shared,
            adUnitID: String,
            placement: String?,
            delegate: GoogleMobileAds.AdLoaderDelegate?,
            nativeAdDelegate: GoogleMobileAds.NativeAdDelegate?
        ) {
            self.adapter = adapter
            self.adUnitID = adUnitID
            self.placement = placement
            self.loaderDelegate = delegate
            self.nativeLoaderDelegate = delegate as? GoogleMobileAds.NativeAdLoaderDelegate
            self.nativeAdDelegate = nativeAdDelegate
        }

        var forwardedLoaderDelegate: GoogleMobileAds.AdLoaderDelegate? {
            self.loaderDelegate
        }

        func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didReceive nativeAd: GoogleMobileAds.NativeAd) {
            let responseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
            self.adapter.trackLoaded(
                responseInfo: responseInfo,
                placement: self.placement,
                adUnitID: self.adUnitID,
                adFormat: RevenueCat.AdFormat.native
            )

            let existingDelegate = self.nativeAdDelegate ?? nativeAd.delegate
            let trackingDelegate = Tracking.NativeAdDelegate(
                adapter: self.adapter,
                delegate: existingDelegate,
                placement: self.placement,
                adUnitID: self.adUnitID
            )
            self.adapter.retainNativeDelegate(trackingDelegate, for: nativeAd)
            nativeAd.delegate = trackingDelegate

            let adapter = self.adapter
            let placement = self.placement
            let adUnitID = self.adUnitID
            let existingPaidHandler = nativeAd.paidEventHandler
            nativeAd.paidEventHandler = { [weak nativeAd] adValue in
                guard let nativeAd else {
                    existingPaidHandler?(adValue)
                    return
                }
                let paidResponseInfo: GoogleMobileAds.ResponseInfo? = nativeAd.responseInfo
                adapter.trackRevenue(
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

        func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didFailToReceiveAdWithError error: Error) {
            self.adapter.trackFailedToLoad(
                placement: self.placement,
                adUnitID: self.adUnitID,
                adFormat: RevenueCat.AdFormat.native,
                error: error
            )
            self.loaderDelegate?.adLoader(adLoader, didFailToReceiveAdWithError: error)
        }

        func adLoaderDidFinishLoading(_ adLoader: GoogleMobileAds.AdLoader) {
            self.loaderDelegate?.adLoaderDidFinishLoading?(adLoader)
        }

    }

}

#endif
