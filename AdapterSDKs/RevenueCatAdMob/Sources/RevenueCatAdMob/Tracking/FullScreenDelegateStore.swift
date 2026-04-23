//
//  FullScreenDelegateStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds the tracking ``Tracking/FullScreenContentDelegate`` for a full-screen ad.
    ///
    /// Uses an Obj-C associated object so the wrapper lives exactly as long as its owning ad,
    /// which is how AdMob expects full-screen content delegates to be retained.
    final class FullScreenDelegateStore {

        private static var key: UInt8 = 0

        /// Returns the tracking delegate previously associated with `object`, if any.
        func retrieve(for object: AnyObject) -> FullScreenContentDelegate? {
            objc_getAssociatedObject(object, &Self.key) as? FullScreenContentDelegate
        }

        /// Associates `delegate` with `object` using a non-atomic retain so the wrapper
        /// stays alive for the lifetime of the ad.
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
