//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallMediaAccessibility.swift
//
//  Created by Michael S. Muegel on 8/27/26.

import SwiftUI

/// Tri-state so `nil` preserves each render site's existing default: image components
/// are hidden from screen readers today, while background images are not.
struct PaywallImagesAccessibilityHiddenKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

/// Icons are announced today, so the default keeps them audible until an app opts out.
struct PaywallIconsAccessibilityHiddenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {

    var paywallImagesAccessibilityHidden: Bool? {
        get { self[PaywallImagesAccessibilityHiddenKey.self] }
        set { self[PaywallImagesAccessibilityHiddenKey.self] = newValue }
    }

    var paywallIconsAccessibilityHidden: Bool {
        get { self[PaywallIconsAccessibilityHiddenKey.self] }
        set { self[PaywallIconsAccessibilityHiddenKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Removes decorative paywall media from the accessibility tree, without changing how it draws.
    ///
    /// Do not "simplify" to `accessibilityHidden`: verified on device, it is disregarded on this
    /// subtree in every placement, and `accessibilityElement(children: .ignore)` leaves the
    /// wrapper focusable with nothing to say.
    @ViewBuilder
    func paywallDecorativeMedia(hidden: Bool) -> some View {
        if hidden {
            self.accessibilityRepresentation { Color.clear }
        } else {
            self
        }
    }

    /// Hides every paywall image, image components and background images alike, from VoiceOver.
    ///
    /// Paywall images carry no accessibility metadata, so decorative ones (logos, hero art) are
    /// announced as unlabeled images. Apply this to the paywall view itself: a paywall presented
    /// in a sheet gets its own hierarchy, so the presenting view does not reach it.
    ///
    /// ```swift
    /// .sheet(isPresented: $isPresented) {
    ///     PaywallView()
    ///         .paywallImagesAccessibilityHidden()
    /// }
    /// ```
    public func paywallImagesAccessibilityHidden(_ hidden: Bool = true) -> some View {
        environment(\.paywallImagesAccessibilityHidden, hidden)
    }

    /// Hides every paywall icon (checkmarks, feature glyphs) from VoiceOver.
    ///
    /// Icons are announced by default. Apply to the paywall view itself, for the same reason as
    /// ``paywallImagesAccessibilityHidden(_:)``.
    public func paywallIconsAccessibilityHidden(_ hidden: Bool = true) -> some View {
        environment(\.paywallIconsAccessibilityHidden, hidden)
    }

}
