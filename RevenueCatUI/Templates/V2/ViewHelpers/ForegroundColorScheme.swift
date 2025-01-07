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

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ForegroundColorSchemeModifier: ViewModifier {

    @Environment(\.colorScheme)
    var colorScheme

    var foregroundColorScheme: PaywallComponent.ColorScheme
    var uiConfigProvider: UIConfigProvider

    func body(content: Content) -> some View {
        content.foregroundColorScheme(
            self.foregroundColorScheme,
            colorScheme: self.colorScheme,
            uiConfigProvider: self.uiConfigProvider
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func foregroundColorScheme(
        _ colorScheme: PaywallComponent.ColorScheme,
        uiConfigProvider: UIConfigProvider
    ) -> some View {
        self.modifier(ForegroundColorSchemeModifier(foregroundColorScheme: colorScheme,
                                                    uiConfigProvider: uiConfigProvider))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {
    @ViewBuilder
    func foregroundColorScheme(
        _ color: PaywallComponent.ColorScheme,
        colorScheme: ColorScheme,
        uiConfigProvider: UIConfigProvider
    ) -> some View {
        switch color.effectiveColor(for: colorScheme) {
        case .hex, .alias:
            let color = color.toDynamicColor(uiConfigProvider: uiConfigProvider)

            // Do not apply a clear text color
            // Use the default color
            if color != Color.clear {
                self.foregroundColor(color)
            } else {
                self
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
