//
//  BannerPaidEventHandlerStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import ObjectiveC.runtime

@available(iOS 15.0, *)
internal extension Tracking {

    /// Holds paid-event wrapper state for a `GoogleMobileAds.BannerView`.
    ///
    /// Stores the original paid-event handler plus an idempotency flag using
    /// Obj-C associated objects so the state is tied to the banner's lifetime.
    final class BannerPaidEventHandlerStore {

        private static var originalPaidHandlerKey: UInt8 = 0
        private static var didInstallWrapperKey: UInt8 = 0

        func retrieveOriginalPaidHandler(for object: AnyObject) -> ((GoogleMobileAds.AdValue) -> Void)? {
            objc_getAssociatedObject(object, &Self.originalPaidHandlerKey)
                as? ((GoogleMobileAds.AdValue) -> Void)
        }

        func retainOriginalPaidHandler(_ handler: ((GoogleMobileAds.AdValue) -> Void)?, for object: AnyObject) {
            objc_setAssociatedObject(
                object,
                &Self.originalPaidHandlerKey,
                handler,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }

        func didInstallWrapper(for object: AnyObject) -> Bool {
            (objc_getAssociatedObject(object, &Self.didInstallWrapperKey) as? NSNumber)?.boolValue ?? false
        }

        func setDidInstallWrapper(for object: AnyObject) {
            objc_setAssociatedObject(
                object,
                &Self.didInstallWrapperKey,
                NSNumber(value: true),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

    }

}

#endif
