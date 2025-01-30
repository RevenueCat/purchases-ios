//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Fill.swift
//
//  Created by Mark Villacampa on 24/1/25.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Shape {

    @ViewBuilder
    func fillColorScheme(
        _ color: DisplayableColorScheme,
        colorScheme: ColorScheme
    ) -> some View {
        let effectiveColor = color.effectiveColor(for: colorScheme)
        switch effectiveColor {
        case .hex:
            // Do not apply a clear text color
            // Use the default color
            if color.hasError {
                self.fill()
            } else {
                self.fill(color.toDynamicColor())
            }
        case .linear(let degrees, _):
            self.fill(
                LinearGradient(
                    gradient: effectiveColor.toGradient(),
                    startPoint: UnitPoint(angle: Angle(degrees: Double(degrees))),
                    endPoint: UnitPoint(angle: Angle(degrees: Double(degrees+180)))
                )
            )
        case .radial:
            self.fill(
                RadialGradient(
                    gradient: effectiveColor.toGradient(),
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
        }

    }
}

#endif
