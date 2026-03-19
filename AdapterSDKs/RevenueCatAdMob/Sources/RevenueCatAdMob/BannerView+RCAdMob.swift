//
//  BannerView+RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

private enum RCBannerAssociatedKeys {
    static var trackingDelegate: UInt8 = 0
    static var originalPaidHandler: UInt8 = 0
    static var didInstallPaidHandlerWrapper: UInt8 = 0
}

@available(iOS 15.0, *)
internal extension GoogleMobileAds.BannerView {

    func loadAndTrack(
        request: GoogleMobileAds.Request,
        placement: String?,
        delegate: (any GoogleMobileAds.BannerViewDelegate)?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        rcAdMob: RCAdMob
    ) {
        let previousDelegate = (self.delegate as? RCAdMobBannerViewDelegate)?.delegate ?? self.delegate
        let effectiveDelegate = delegate ?? previousDelegate

        let trackingDelegate = RCAdMobBannerViewDelegate(
            rcAdMob: rcAdMob,
            delegate: effectiveDelegate,
            placement: placement
        )
        objc_setAssociatedObject(
            self,
            &RCBannerAssociatedKeys.trackingDelegate,
            trackingDelegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        self.delegate = trackingDelegate

        installPaidEventHandlerWrapper(
            paidEventHandler: paidEventHandler,
            placement: placement,
            rcAdMob: rcAdMob
        )

        self.load(request)
    }

    private func installPaidEventHandlerWrapper(
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        placement: String?,
        rcAdMob: RCAdMob
    ) {
        let storedPaidHandler = objc_getAssociatedObject(self, &RCBannerAssociatedKeys.originalPaidHandler)
            as? ((GoogleMobileAds.AdValue) -> Void)
        let didInstallWrapper = (objc_getAssociatedObject(self, &RCBannerAssociatedKeys.didInstallPaidHandlerWrapper)
            as? NSNumber)?.boolValue ?? false
        let previousPaidHandler = didInstallWrapper ? storedPaidHandler : (storedPaidHandler ?? self.paidEventHandler)
        let effectivePaidHandler = paidEventHandler ?? previousPaidHandler
        objc_setAssociatedObject(
            self,
            &RCBannerAssociatedKeys.originalPaidHandler,
            effectivePaidHandler,
            .OBJC_ASSOCIATION_COPY_NONATOMIC
        )

        let capturedUserHandler = effectivePaidHandler
        self.paidEventHandler = { [weak self] adValue in
            if let self {
                let responseInfo: GoogleMobileAds.ResponseInfo? = self.responseInfo
                rcAdMob.trackRevenue(
                    placement: placement,
                    adUnitID: self.adUnitID,
                    adFormat: RevenueCat.AdFormat.banner,
                    responseInfo: responseInfo,
                    adValue: adValue
                )
                let storedPaidHandler = objc_getAssociatedObject(self, &RCBannerAssociatedKeys.originalPaidHandler)
                    as? ((GoogleMobileAds.AdValue) -> Void)
                storedPaidHandler?(adValue)
            } else {
                // Banner was deallocated; still invoke user's handler (e.g. ad SDK invoked callback after view gone).
                capturedUserHandler?(adValue)
            }
        }
        objc_setAssociatedObject(
            self,
            &RCBannerAssociatedKeys.didInstallPaidHandlerWrapper,
            NSNumber(value: true),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.BannerView {

    /// Loads a banner ad and tracks ad events with RevenueCat while optionally forwarding callbacks.
    ///
    /// - Parameters:
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - delegate: Optional delegate that will receive banner ad callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    func loadAndTrack(
        request: GoogleMobileAds.Request,
        placement: String? = nil,
        delegate: (any GoogleMobileAds.BannerViewDelegate)? = nil,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)? = nil
    ) {
        self.loadAndTrack(
            request: request,
            placement: placement,
            delegate: delegate,
            paidEventHandler: paidEventHandler,
            rcAdMob: .shared
        )
    }

}

#endif
