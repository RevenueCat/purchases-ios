//
//  AssociatedObjectStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Retains and retrieves a strongly-typed value on an owner via Obj-C associated objects.
    ///
    /// The value lives exactly as long as the owner. Each store instance allocates its own key,
    /// so two stores of the same value type never collide.
    final class AssociatedObjectStore<Value: AnyObject> {

        private let key = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)

        deinit {
            self.key.deallocate()
        }

        func retrieve(for object: AnyObject) -> Value? {
            objc_getAssociatedObject(object, self.key) as? Value
        }

        func retain(_ value: Value?, for object: AnyObject) {
            objc_setAssociatedObject(
                object,
                self.key,
                value,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

    }

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
