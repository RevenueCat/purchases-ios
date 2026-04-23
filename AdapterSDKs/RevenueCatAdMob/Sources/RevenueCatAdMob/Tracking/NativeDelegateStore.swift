//
//  NativeDelegateStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds the tracking ``Tracking/NativeAdDelegate`` for a native ad.
    ///
    /// Uses an Obj-C associated object so the wrapper lives exactly as long as the
    /// `GoogleMobileAds.NativeAd` it tracks (AdMob holds native ad delegates weakly).
    final class NativeDelegateStore {

        private static var key: UInt8 = 0

        /// Associates `delegate` with `object` using a non-atomic retain so the wrapper
        /// stays alive for the lifetime of the native ad.
        func retain(_ delegate: AnyObject, for object: AnyObject) {
            objc_setAssociatedObject(
                object,
                &Self.key,
                delegate,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

    }

}

#endif
