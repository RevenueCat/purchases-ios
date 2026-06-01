//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallScrollEnvironment.swift
//

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallRootStackIsZLayerKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallAncestorScrollsVerticallyKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// `true` when the paywall root stack is a z-layer (used to enable z-layer scrolling in bounded containers).
    var paywallRootStackIsZLayer: Bool {
        get { self[PaywallRootStackIsZLayerKey.self] }
        set { self[PaywallRootStackIsZLayerKey.self] = newValue }
    }

    /// `true` when this view is inside a vertically scrolling Paywalls V2 stack container.
    var paywallAncestorScrollsVertically: Bool {
        get { self[PaywallAncestorScrollsVerticallyKey.self] }
        set { self[PaywallAncestorScrollsVerticallyKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func paywallMarkingVerticalScrollContainer<Content: View>(
        axis: Axis,
        @ViewBuilder content: () -> Content
    ) -> some View {
        PaywallVerticalScrollContainer(axis: axis, content: content())
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallVerticalScrollContainer<Content: View>: View {

    @Environment(\.paywallAncestorScrollsVertically)
    private var ancestorScrollsVertically

    let axis: Axis
    let content: Content

    var body: some View {
        content
            .environment(
                \.paywallAncestorScrollsVertically,
                self.ancestorScrollsVertically || self.axis == .vertical
            )
    }
}

#endif
