//
//  DelegateStores.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds the tracking ``Tracking/FullScreenContentDelegate`` for a full-screen ad.
    typealias FullScreenDelegateStore = AssociatedObjectStore<FullScreenContentDelegate>

    /// Holds the per-banner tracking state (``Tracking/BannerTrackingState``) for a banner view.
    typealias BannerStateStore = AssociatedObjectStore<BannerTrackingState>

    /// Holds the tracking ``Tracking/NativeAdDelegate`` for a native ad.
    typealias NativeDelegateStore = AssociatedObjectStore<NativeAdDelegate>

    /// Holds the ``Tracking/NativeAdLoaderDelegateProxy`` for a `GoogleMobileAds.AdLoader`.
    typealias NativeAdLoaderProxyStore = AssociatedObjectStore<NativeAdLoaderDelegateProxy>

}

#endif
