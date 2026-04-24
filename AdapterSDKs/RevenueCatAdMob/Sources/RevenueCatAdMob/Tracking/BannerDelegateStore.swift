//
//  BannerDelegateStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds the tracking ``Tracking/BannerViewDelegate`` for a banner view.
    ///
    /// Uses an Obj-C associated object so the wrapper lives exactly as long as the
    /// `GoogleMobileAds.BannerView` it tracks (AdMob holds banner delegates weakly).
    final class BannerDelegateStore {

        private static var key: UInt8 = 0

        /// Associates `delegate` with `object` using a non-atomic retain so the wrapper
        /// stays alive for the lifetime of the banner.
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
