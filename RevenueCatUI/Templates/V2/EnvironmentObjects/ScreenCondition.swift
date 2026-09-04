//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScreenCondition.swift
//
//  Created by Josh Holtz on 11/14/24.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

enum ScreenCondition {

    case compact, medium, expanded

    static func from(_ sizeClass: UserInterfaceSizeClass?) -> Self {
        guard let sizeClass else {
            return .compact
        }

        switch sizeClass {
        case .compact:
            return .compact
        case .regular:
            return .medium
        @unknown default:
            return .compact
        }
    }

}

struct ScreenConditionKey: EnvironmentKey {
    static let defaultValue = ScreenCondition.compact
}

/// Size of the window the paywall is rendered in, measured at the paywall root.
/// Used to evaluate window size conditions (adaptive layouts on foldables/tablets).
/// `nil` until the first layout pass completes.
struct PaywallWindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

extension EnvironmentValues {

    var screenCondition: ScreenCondition {
        get { self[ScreenConditionKey.self] }
        set { self[ScreenConditionKey.self] = newValue }
    }

    var paywallWindowSize: CGSize? {
        get { self[PaywallWindowSizeKey.self] }
        set { self[PaywallWindowSizeKey.self] = newValue }
    }

}

/// Measures the modified view's size (layout-neutral background reader) and
/// republishes it as `\.paywallWindowSize` for window size condition evaluation.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallWindowSizeReaderModifier: ViewModifier {

    @State private var windowSize: CGSize?

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { self.windowSize = proxy.size }
                        .onChangeOf(proxy.size) { self.windowSize = $0 }
                }
            )
            .environment(\.paywallWindowSize, self.windowSize)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Measures this view's size and provides it to descendants as the paywall
    /// window size for window size condition evaluation. Apply at the paywall root.
    func measurePaywallWindowSize() -> some View {
        self.modifier(PaywallWindowSizeReaderModifier())
    }

}

#endif
