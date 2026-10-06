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
    /// - Root z-layer paywalls scroll by default so tall hero content fits in bounded containers.
    /// - Root overflow settings take precedence over that default.
    /// - Non-root z-layers never scroll, regardless of overflow or ancestor scrolling.
    static func shouldApplyScroll(
        stackScrollPreference: Bool?,
        isRootStack: Bool,
        ancestorScrollsVertically: Bool
    ) -> Bool {
        guard isRootStack, !ancestorScrollsVertically else {
            return false
        }

        return stackScrollPreference ?? true
    }
}

#endif
