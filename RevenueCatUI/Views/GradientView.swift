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

#if !os(tvOS) // For Paywalls V2

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

    // Calculate the start and end points of the gradient following the CSS linear-gradient spec
    // https://developer.mozilla.org/en-US/docs/Web/CSS/gradient/linear-gradient

    // Heavily inspired by this blog post by Mukhtar Bimurat
    // https://link.medium.com/LczMO6j8YQb
    private func calculatePoints(angle: Angle, rect: CGRect) -> (start: UnitPoint, end: UnitPoint) {
        // Calculate the diagonal of the rectangle using the Pythagorean theorem
        let diagonal = sqrt(pow(rect.width, 2) + pow(rect.height, 2))
        // Calculates the angle between the rectangle's diagonal and its width
        let angleBetweenDiagonalAndWidth = acos(rect.width / diagonal)

        // Handle extreme angles
        // Multiply by -1 to make it clockwise and subtract 270 degrees to follow CSS's angle convention.
        let degrees = ((-angle.degrees - 270).truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        // Convert the angle to radians.
        let angleInRadians = Double.pi * degrees / 180.0

        // Calculate the angle between the diagonal and the gradient line
        let angleBetweenDiagonalAndGradientLine: CGFloat
        if (degrees > 90 && degrees < 180) || (degrees > 270 && degrees < 360) {
            angleBetweenDiagonalAndGradientLine = .pi - angleInRadians - angleBetweenDiagonalAndWidth
         } else {
             angleBetweenDiagonalAndGradientLine = angleInRadians - angleBetweenDiagonalAndWidth
         }

        // Get half the length of the gradient line, and calculate the vertical and horizontal offsets from the center
        let halfGradientLine = abs(cos(angleBetweenDiagonalAndGradientLine) * diagonal) / 2
        let horizontalOffset = halfGradientLine * cos(angleInRadians)
        let verticalOffset = halfGradientLine * sin(angleInRadians)

        // Convert the start and end points to UnitPoint coordinates (0-1 range)
        let centerX = 0.5
        let centerY = 0.5
        let start = UnitPoint(x: centerX - horizontalOffset / rect.width, y: centerY + verticalOffset / rect.height)
        let end = UnitPoint(x: centerX + horizontalOffset / rect.width, y: centerY - verticalOffset / rect.height)

        return (start, end)
    }

    var body: some View {
        GeometryReader { geometry in
            switch gradientStyle {
            case .linear(let degrees):
                let points = calculatePoints(angle: .degrees(Double(degrees)), rect: geometry.frame(in: .local))
                LinearGradient(
                    gradient: gradient,
                    startPoint: points.start,
                    endPoint: points.end
                )
            case .radial:
                RadialGradient(
                    gradient: gradient,
                    center: .center,
                    startRadius: 0,
                    endRadius: min(geometry.size.width, geometry.size.height)
                )
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct GradientView_Previews: PreviewProvider {

    static private func gradientView(style: GradientView.GradientStyle) -> some View {
        GradientView(
            lightGradient: .init(stops: [
                .init(color: .blue, location: 0),
                .init(color: .red, location: 0.5),
                .init(color: .black, location: 1)
            ]),
            darkGradient: .init(stops: [
                .init(color: .red, location: 0),
                .init(color: .blue, location: 0.5),
                .init(color: .black, location: 1)
            ]),
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
            LinearGradientPreview(label: "Linear 0º", degrees: 0)
            LinearGradientPreview(label: "Linear 45º", degrees: 45)
            LinearGradientPreview(label: "Linear 90º", degrees: 90)
            LinearGradientPreview(label: "Linear 135º", degrees: 135)
            LinearGradientPreview(label: "Linear 180º", degrees: 180)
            LinearGradientPreview(label: "Linear 225º", degrees: 225)
            LinearGradientPreview(label: "Linear 270º", degrees: 270)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Linear")
    }

    /// Helper view to preview linear gradients with different angles. This is useful so to keep down the
    /// number of views in the container holding all of the previews to avoid compilation issues
    /// with the preview.
    private struct LinearGradientPreview: View {

        let label: String
        let degrees: Int

        var body: some View {
            VStack {
                Text(label)
                gradientView(style: .linear(degrees))
            }
        }
    }

}

#endif
