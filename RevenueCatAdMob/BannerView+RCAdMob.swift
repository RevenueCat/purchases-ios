//
//  BannerView+RCAdMob.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime
@_spi(Experimental) import RevenueCat

private enum RCBannerAssociatedKeys {
    static var trackingDelegate: UInt8 = 0
    static var originalPaidHandler: UInt8 = 0
    static var didInstallPaidHandlerWrapper: UInt8 = 0
}

// MARK: - Internal implementation (shared across SDK versions)

@available(iOS 15.0, *)
internal extension RCGoogleMobileAds.BannerView {

    func loadAndTrack(
        request: RCGoogleMobileAds.Request,
        placement: String?,
        delegate: (any RCGoogleMobileAds.BannerViewDelegate)?,
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
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
        paidEventHandler: ((RCGoogleMobileAds.AdValue) -> Void)?,
        placement: String?,
        rcAdMob: RCAdMob
    ) {
        let storedPaidHandler = objc_getAssociatedObject(self, &RCBannerAssociatedKeys.originalPaidHandler)
            as? ((RCGoogleMobileAds.AdValue) -> Void)
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
                let responseInfo: RCGoogleMobileAds.ResponseInfo? = self.responseInfo
                rcAdMob.trackRevenue(
                    placement: placement,
                    adUnitID: self.adUnitID,
                    adFormat: RevenueCat.AdFormat.banner,
                    responseInfo: responseInfo,
                    adValue: adValue
                )
                let storedPaidHandler = objc_getAssociatedObject(self, &RCBannerAssociatedKeys.originalPaidHandler)
                    as? ((RCGoogleMobileAds.AdValue) -> Void)
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

// MARK: - Public API

#if !RC_ADMOB_SDK_11
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
#else // RC_ADMOB_SDK_11
@available(iOS 15.0, *)
@_spi(Experimental) public extension GADBannerView {

    /// Loads a banner ad and tracks ad events with RevenueCat while optionally forwarding callbacks.
    ///
    /// - Parameters:
    ///   - request: The AdMob request used to load the ad.
    ///   - placement: Optional placement label used for RevenueCat analytics.
    ///   - delegate: Optional delegate that will receive banner ad callbacks.
    ///     Held **weakly** internally; the caller must retain this instance for the lifetime of the ad.
    ///   - paidEventHandler: Optional handler invoked when a paid event is recorded.
    func loadAndTrack(
        request: GADRequest,
        placement: String? = nil,
        delegate: GADBannerViewDelegate? = nil,
        paidEventHandler: ((GADAdValue) -> Void)? = nil
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

#endif
