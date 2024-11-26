//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GradientView.swift
//
//  Created by Mark Villacampa on 2024-11-24.

import SwiftUI

#if PAYWALL_COMPONENTS

struct GradientView: View {
    enum GradientStyle {
        case linear(Int)
        case radial
    }

    @Environment(\.colorScheme)
    private var colorScheme

    let lightGradient: Gradient
    let darkGradient: Gradient?
    let gradientStyle: GradientStyle

    var gradient: Gradient {
        switch colorScheme {
        case .light:
            lightGradient
        case .dark:
            darkGradient ?? lightGradient
        @unknown default:
            lightGradient
        }
    }

    var body: some View {
        switch gradientStyle {
        case .linear(let degrees):
            LinearGradient(
                gradient: gradient,
                startPoint: .init(angle: Angle(degrees: Double(degrees))),
                endPoint: .init(angle: Angle(degrees: Double(degrees+180)))
            )
        case .radial:
            RadialGradient(
                gradient: gradient,
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        }
    }
}

private extension UnitPoint {

    init(angle: Angle) {
        // Convert the angle to radians
        let radians = angle.radians

        // Calculate the normalized x and y positions
        let xPosition = cos(radians)
        let yPosition = sin(radians)

        // Determine the scaling factor to move the point to the edge of the enclosing square
        let scaleFactor = max(abs(xPosition), abs(yPosition))

        // Scale the x and y coordinates
        let scaledX = xPosition / scaleFactor
        let scaledY = yPosition / scaleFactor

        // Convert the scaled coordinates to a UnitPoint
        self.init(x: (scaledX + 1) / 2, y: (1 - scaledY) / 2)
    }

}

#endif
