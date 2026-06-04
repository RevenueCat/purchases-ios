//
//  AssociatedObjectStore.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import ObjectiveC.runtime

/// Stores and retrieves a strongly-typed value on an owner via Obj-C associated objects.
///
/// The value lives exactly as long as the owner. Each store instance allocates its own key,
/// so two stores of the same value type never collide.
@available(iOS 15.0, *)
internal final class AssociatedObjectStore<Value: AnyObject> {

    private let key = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)

    deinit {
        self.key.deallocate()
    }

    func retrieve(for object: AnyObject) -> Value? {
        objc_getAssociatedObject(object, self.key) as? Value
    }

    func set(_ value: Value?, for object: AnyObject) {
        objc_setAssociatedObject(
            object,
            self.key,
            value,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

#endif
