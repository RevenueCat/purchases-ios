//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ForegroundColorScheme.swift
//
//  Created by MarkVillacampa on 27/11/24.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ForegroundColorSchemeModifier: ViewModifier {

    @Environment(\.colorScheme)
    var colorScheme

    var foregroundColorScheme: DisplayableColorScheme

    func body(content: Content) -> some View {
        content.foregroundColorScheme(
            self.foregroundColorScheme,
            colorScheme: self.colorScheme
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func foregroundColorScheme(
        _ colorScheme: DisplayableColorScheme
    ) -> some View {
        self.modifier(ForegroundColorSchemeModifier(foregroundColorScheme: colorScheme))
    }
}

/// Tints a view with a solid color scheme. SwiftUI renders `Text` links in the tint color, ignoring the
/// foreground color, so this keeps markdown links in the paywall's text color.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TintColorSchemeModifier: ViewModifier {

    @Environment(\.colorScheme)
    var colorScheme

    var tintColorScheme: DisplayableColorScheme

    func body(content: Content) -> some View {
        if case .hex = self.tintColorScheme.effectiveColor(for: self.colorScheme), !self.tintColorScheme.hasError {
            content.tint(self.tintColorScheme.toDynamicColor(with: self.colorScheme))
        } else {
            content
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func tintColorScheme(_ colorScheme: DisplayableColorScheme) -> some View {
        self.modifier(TintColorSchemeModifier(tintColorScheme: colorScheme))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {
    @ViewBuilder
    func foregroundColorScheme(
        _ color: DisplayableColorScheme,
        colorScheme: ColorScheme
    ) -> some View {
        switch color.effectiveColor(for: colorScheme) {
        case .hex:
            // Do not apply a clear text color
            // Use the default color
            if color.hasError {
                self
            } else {
                self.foregroundColor(color.toDynamicColor(with: colorScheme))
            }
        case .linear(let degrees, _):
            self.overlay {
                GradientView(
                    lightGradient: color.light.toGradient(),
                    darkGradient: color.dark?.toGradient(),
                    gradientStyle: .linear(degrees)
                )
                .mask(
                    self
                )
            }
        case .radial:
            self.overlay {
                GradientView(
                    lightGradient: color.light.toGradient(),
                    darkGradient: color.dark?.toGradient(),
                    gradientStyle: .radial
                )
                .mask(
                    self
                )
            }
        }
    }
}

#endif
