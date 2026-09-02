//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallZLayerScrollPolicy.swift
//

#if !os(tvOS) // For Paywalls V2

/// Scroll decisions for z-layer stacks in Paywalls V2.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallZLayerScrollPolicy {

    /// Whether a z-layer stack should use vertical scrolling.
    ///
    /// - Root z-layer paywalls scroll so tall hero content fits in bounded containers (e.g. iPad sheets).
    /// - Nested z-layers skip scrolling when an ancestor already scrolls vertically.
    static func shouldApplyScroll(
        stackScrollingEnabled: Bool,
        paywallRootStackIsZLayer: Bool,
        ancestorScrollsVertically: Bool
    ) -> Bool {
        guard !ancestorScrollsVertically else {
            return false
        }

        return stackScrollingEnabled || paywallRootStackIsZLayer
    }
}

#endif
