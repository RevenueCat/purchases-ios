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

    /// Removes decorative paywall media from the accessibility tree, without changing how it
    /// draws.
    ///
    /// Uses `accessibilityRepresentation` rather than `accessibilityHidden`, and that choice is
    /// load-bearing. Verified with VoiceOver on device, on this subtree:
    ///
    /// - `accessibilityHidden(true)` is disregarded, in every placement tried: on the image, on
    ///   the outermost wrapper, with and without this helper around it.
    /// - `accessibilityElement(children: .ignore)` does reach the children and silences an
    ///   image, but leaves the wrapper focusable, so VoiceOver stops on an element that says
    ///   nothing — worse than announcing it. On icons it did not even silence them.
    /// - `accessibilityRepresentation` substitutes the subtree's accessibility with another
    ///   view's, and an empty `Color` publishes no element at all. VoiceOver skips the media
    ///   entirely while it stays on screen.
    ///
    /// Do not "simplify" this to `accessibilityHidden`.
    @ViewBuilder
    func paywallDecorativeMedia(hidden: Bool) -> some View {
        if hidden {
            self.accessibilityRepresentation { Color.clear }
        } else {
            self
        }
    }

    /// Hides every image in a paywall from VoiceOver and other assistive technologies —
    /// image components and background images alike.
    ///
    /// Paywall images carry no accessibility metadata, so when they are purely decorative
    /// (logos, hero art) screen readers announcing them as unlabeled images is noise.
    /// Apply this to the paywall view itself. These are environment values, and a paywall
    /// presented in a sheet gets its own hierarchy, so applying them to the presenting view
    /// does not reach the paywall:
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

    /// Hides every icon in a paywall (checkmarks, feature glyphs, and other symbols from the
    /// icon library) from VoiceOver and other assistive technologies.
    ///
    /// Icons are announced by default. When they only decorate adjacent text — a checkmark
    /// next to each feature — hiding them removes redundant announcements. Apply this to the
    /// paywall view itself, for the same reason as
    /// ``paywallImagesAccessibilityHidden(_:)``.
    public func paywallIconsAccessibilityHidden(_ hidden: Bool = true) -> some View {
        environment(\.paywallIconsAccessibilityHidden, hidden)
    }

}
