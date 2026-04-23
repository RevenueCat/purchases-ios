//
//  NativeAdLoaderProxyStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds the ``Tracking/NativeAdLoaderDelegateProxy`` for a `GoogleMobileAds.AdLoader`.
    ///
    /// Uses an Obj-C associated object so the proxy lives exactly as long as the loader,
    /// since `AdLoader.delegate` is held weakly.
    final class NativeAdLoaderProxyStore {

        private static var key: UInt8 = 0

        /// Associates `proxy` with `object` using a non-atomic retain so the proxy
        /// stays alive for the lifetime of the ad loader.
        func retain(_ proxy: AnyObject, for object: AnyObject) {
            objc_setAssociatedObject(
                object,
                &Self.key,
                proxy,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

    }

}

#endif
