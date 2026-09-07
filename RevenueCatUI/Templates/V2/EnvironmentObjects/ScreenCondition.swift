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

/// The paywall's rendered bounds in points — not the device screen, so a
/// Split View pane or sheet reports its own size. `nil` where no paywall root
/// has published a size, in which case window size conditions never match.
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Publishes the proposed size as `\.paywallWindowSize` so window size
    /// conditions evaluate synchronously on first layout and re-evaluate live
    /// on rotation and window resize. Apply at the paywall root: the
    /// `GeometryReader` fills its container, so the content must too.
    func measurePaywallWindowSize() -> some View {
        GeometryReader { proxy in
            self.environment(\.paywallWindowSize, proxy.size)
        }
    }

}

#endif
