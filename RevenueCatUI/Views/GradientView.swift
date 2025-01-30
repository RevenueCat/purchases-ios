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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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

    private var gradient: Gradient {
        switch colorScheme {
        case .light:
            return lightGradient
        case .dark:
            return darkGradient ?? lightGradient
        @unknown default:
            return lightGradient
        }
    }

    var body: some View {
        switch gradientStyle {
        case .linear(let degrees):
            LinearGradient(
                gradient: gradient,
                startPoint: UnitPoint(angle: Angle(degrees: Double(degrees))),
                endPoint: UnitPoint(angle: Angle(degrees: Double(degrees+180)))
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct GradientView_Previews: PreviewProvider {

    static private func gradientView(style: GradientView.GradientStyle) -> some View {
        GradientView(
            lightGradient: .init(colors: .init([.red, .black])),
            darkGradient: .init(colors: .init([.blue, .black])),
            gradientStyle: style
        )
    }

    static var previews: some View {
        GradientView(
            lightGradient: .init(colors: .init([.red, .white])),
            darkGradient: .init(colors: .init([.blue, .white])),
            gradientStyle: .radial
        )
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Radial - Dark (should be blue)")

        GradientView(
            lightGradient: .init(colors: .init([.red, .white])),
            darkGradient: .init(colors: .init([.blue, .white])),
            gradientStyle: .radial
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Radial - Light (should be red)")

        GradientView(
            lightGradient: .init(colors: .init([.red, .white])),
            darkGradient: .init(colors: .init([.blue, .white])),
            gradientStyle: .linear(45)
        )
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Linear 45º - Dark (should be blue)")

        GradientView(
            lightGradient: .init(colors: .init([.red, .white])),
            darkGradient: .init(colors: .init([.blue, .white])),
            gradientStyle: .linear(90)
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Linear 90º - Light (should be red)")

        VStack {
            Text("Linear 0º")
            gradientView(style: .linear(0))
            Text("Linear 45º")
            gradientView(style: .linear(45))
            Text("Linear 90º")
            gradientView(style: .linear(90))
            Text("Linear 135º")
            gradientView(style: .linear(135))
            Text("Linear 180º")
            gradientView(style: .linear(180))
            Text("Linear 225º")
            gradientView(style: .linear(225))
            Text("Linear 270º")
            gradientView(style: .linear(270))
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Linear")
    }

}

extension UnitPoint {

    init(angle: Angle) {
        // Convert the angle to radians and negate to make clockwise
        // Subtract π/2 (90 degrees) to place an angle of 0 degrees at the top
        let radians = -angle.radians - (.pi / 2)

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
