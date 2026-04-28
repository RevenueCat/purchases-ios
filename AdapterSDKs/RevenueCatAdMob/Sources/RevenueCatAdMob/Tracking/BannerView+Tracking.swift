//
//  BannerView+Tracking.swift
//
//  Created by RevenueCat on 2/13/26.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    /// Per-banner state attached to a `BannerView` via an associated object.
    ///
    /// Presence of this object signals "we have already wrapped this banner", which is what
    /// allows us to distinguish a never-wrapped banner from one wrapped with a nil user handler.
    final class BannerTrackingState {
        var delegate: BannerViewDelegate?
        var originalPaidHandler: ((GoogleMobileAds.AdValue) -> Void)?
    }

}

@available(iOS 15.0, *)
internal extension GoogleMobileAds.BannerView {

    func loadAndTrack(
        request: GoogleMobileAds.Request,
        placement: String?,
        delegate: (any GoogleMobileAds.BannerViewDelegate)?,
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        adapter: Tracking.Adapter
    ) {
        let previousDelegate = (self.delegate as? Tracking.BannerViewDelegate)?.delegate ?? self.delegate
        let effectiveDelegate = delegate ?? previousDelegate

        let trackingDelegate = Tracking.BannerViewDelegate(
            adapter: adapter,
            delegate: effectiveDelegate,
            placement: placement
        )

        let isFirstWrap: Bool
        let state: Tracking.BannerTrackingState
        if let existing = adapter.bannerStateStore.retrieve(for: self) {
            state = existing
            isFirstWrap = false
        } else {
            state = Tracking.BannerTrackingState()
            adapter.bannerStateStore.retain(state, for: self)
            isFirstWrap = true
        }
        state.delegate = trackingDelegate
        self.delegate = trackingDelegate

        installPaidEventHandlerWrapper(
            paidEventHandler: paidEventHandler,
            placement: placement,
            adapter: adapter,
            state: state,
            isFirstWrap: isFirstWrap
        )

        self.load(request)
    }

    private func installPaidEventHandlerWrapper(
        paidEventHandler: ((GoogleMobileAds.AdValue) -> Void)?,
        placement: String?,
        adapter: Tracking.Adapter,
        state: Tracking.BannerTrackingState,
        isFirstWrap: Bool
    ) {
        let previousPaidHandler = isFirstWrap ? self.paidEventHandler : state.originalPaidHandler
        let effectivePaidHandler = paidEventHandler ?? previousPaidHandler
        state.originalPaidHandler = effectivePaidHandler

        self.paidEventHandler = { [weak self] adValue in
            if let self {
                let responseInfo: GoogleMobileAds.ResponseInfo? = self.responseInfo
                adapter.trackRevenue(
                    placement: placement,
                    adUnitID: self.adUnitID,
                    adFormat: RevenueCat.AdFormat.banner,
                    responseInfo: responseInfo,
                    adValue: adValue
                )
            }
            state.originalPaidHandler?(adValue)
        }
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
            adapter: .shared
        )
    }

}

#endif
