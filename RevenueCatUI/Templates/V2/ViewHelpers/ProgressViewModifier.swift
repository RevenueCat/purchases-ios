//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProgressViewModifier.swift
//
//  Created by Josh Holtz on 2/13/25.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ProgressViewModifier: ViewModifier {

    @Environment(\.colorScheme)
    private var colorScheme

    var backgroundStyle: BackgroundStyle?

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(progressView)
    }

    @ViewBuilder
    private var progressView: some View {
        switch backgroundStyle {
        case .color(let displayableColorScheme):
            let colorInfo = displayableColorScheme.effectiveColor(for: colorScheme)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: bestTint(for: colorInfo)))
        case .image, .none:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }

    private func bestTint(for colorInfo: DisplayableColorInfo) -> Color {
        switch colorInfo {
        case .hex:
            return colorInfo.toColor(fallback: .black).brightness() > 0.6 ? .black : .white
        case .linear, .radial:
            let gradient = colorInfo.toGradient()
            let averageBrightness = gradient.stops
                .compactMap { $0.color.brightness() }
                .reduce(0, +) / CGFloat(gradient.stops.count)
            return averageBrightness > 0.6 ? .black : .white
        }
    }
    
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension Color {

    /// Calculates the perceived brightness of the color.
    /// Uses the standard luminance formula for relative brightness perception.
    func brightness() -> CGFloat {
        guard let uiColor = UIColor(self).cgColor.components else { return 1.0 }

        // Ensure the color has at least three components (R, G, B)
        guard uiColor.count >= 3 else { return 1.0 }

        let red = uiColor[0]
        let green = uiColor[1]
        let blue = uiColor[2]

        // Standard luminance coefficients for sRGB (per ITU-R BT.709)
        let redCoefficient: CGFloat = 0.299
        let greenCoefficient: CGFloat = 0.587
        let blueCoefficient: CGFloat = 0.114

        // Compute the brightness based on the weighted sum of RGB components
        return (red * redCoefficient) + (green * greenCoefficient) + (blue * blueCoefficient)
    }
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func progressOverlay(for backgroundStyle: BackgroundStyle?) -> some View {
        self.modifier(ProgressViewModifier(backgroundStyle: backgroundStyle))
    }

}
