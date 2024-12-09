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

    func body(content: Content) -> some View {
        content.foregroundColorScheme(foregroundColorScheme, colorScheme: colorScheme)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func foregroundColorScheme(_ colorScheme: PaywallComponent.ColorScheme) -> some View {
        self.modifier(ForegroundColorSchemeModifier(foregroundColorScheme: colorScheme))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {
    @ViewBuilder
    func foregroundColorScheme(_ color: PaywallComponent.ColorScheme, colorScheme: ColorScheme) -> some View {
        switch color.effectiveColor(for: colorScheme) {
        case .hex, .alias:
            self.foregroundColor(color.toDynamicColor())
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
