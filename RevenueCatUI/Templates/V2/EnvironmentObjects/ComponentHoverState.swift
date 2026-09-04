//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentHoverState.swift
//
//  Created by Josh Holtz on 9/2/26.

import Foundation
import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct ComponentHoverStateKey: EnvironmentKey {

    static let defaultValue: Bool = false

}

extension EnvironmentValues {

    /// Whether this component, or an ancestor that declares hover overrides, is currently hovered.
    var componentHoverState: Bool {
        get { self[ComponentHoverStateKey.self] }
        set { self[ComponentHoverStateKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Tracks pointer hover for a component and propagates the hover state to its subtree,
    /// so descendants' hover overrides also apply while an ancestor is hovered (like CSS `:hover`).
    /// Hover tracking is only attached when the component declares hover overrides
    /// (`trackingEnabled`), so components without them add no pointer tracking.
    func componentHoverState(_ isHovered: Binding<Bool>, trackingEnabled: Bool) -> some View {
        modifier(ComponentHoverStateModifier(isHovered: isHovered, trackingEnabled: trackingEnabled))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ComponentHoverStateModifier: ViewModifier {

    @Binding var isHovered: Bool
    let trackingEnabled: Bool

    @Environment(\.componentHoverState)
    private var inheritedHoverState

    func body(content: Content) -> some View {
        self.trackingHover(content)
            .environment(\.componentHoverState, self.isHovered || self.inheritedHoverState)
    }

    @ViewBuilder
    private func trackingHover(_ content: Content) -> some View {
        #if os(watchOS)
        content
        #else
        if self.trackingEnabled {
            content.onHover { self.isHovered = $0 }
        } else {
            content
        }
        #endif
    }

}

#endif
