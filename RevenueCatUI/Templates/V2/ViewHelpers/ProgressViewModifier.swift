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
extension View {

    func progressOverlay(for backgroundStyle: BackgroundStyle?) -> some View {
        self.modifier(ProgressViewModifier(backgroundStyle: backgroundStyle))
    }

}
