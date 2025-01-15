//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Shape.swift
//
//  Created by Josh Holtz on 9/30/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ShapeModifier: ViewModifier {

    struct BorderInfo: Hashable {

        let color: Color
        let width: CGFloat

        init(color: Color, width: Double) {
            self.color = color
            self.width = width
        }

    }

    enum Shape: Hashable {

        case rectangle(RadiusInfo?)
        case pill
        case circle
        case concave
        case convex

    }

    struct RadiusInfo: Hashable {

        let topLeft: Double?
        let topRight: Double?
        let bottomLeft: Double?
        let bottomRight: Double?

    }

    var border: BorderInfo?
    var shape: Shape
    var shadow: ShadowModifier.ShadowInfo?
    var background: BackgroundStyle?
    var uiConfigProvider: UIConfigProvider?

    init(border: BorderInfo?,
         shape: Shape?,
         shadow: ShadowModifier.ShadowInfo?,
         background: BackgroundStyle?,
         uiConfigProvider: UIConfigProvider?
    ) {
        self.border = border
        self.shape = shape ?? .rectangle(nil)
        self.shadow = shadow
        self.background = background
        self.uiConfigProvider = uiConfigProvider
    }

    func body(content: Content) -> some View {
        switch self.shape {
        case .rectangle(let radiusInfo):
            let shape = self.effectiveRectangleShape(radiusInfo: radiusInfo)
            let effectiveShape = shape ?? Rectangle().eraseToAnyInsettableShape()
            content
                .backgroundStyle(background)
                // We want to clip only in case there is a non-Rectangle shape
                // or if there's a border, otherwise we let the background color
                // extend behind the safe areas
                .applyIfLet(shape) { view, shape in
                    view.clipShape(shape)
                }
                .applyIfLet(border) { view, border in
                    view.clipShape(effectiveShape).overlay {
                        effectiveShape.strokeBorder(border.color, lineWidth: border.width)
                    }
                }
                .applyIfLet(shadow) { view, shadow in
                    view.shadow(shadow: shadow, shape: effectiveShape)
                }
        case .pill:
            let shape = Capsule(style: .circular)
            content
                .backgroundStyle(background)
                .clipShape(shape)
                .applyIfLet(border) { view, border in
                    view.overlay {
                        shape.strokeBorder(border.color, lineWidth: border.width)
                    }
                }.applyIfLet(shadow) { view, shadow in
                    view.shadow(shadow: shadow, shape: shape)
                }
        case .circle:
            let shape = Circle()
            content
                .backgroundStyle(background)
                .clipShape(shape)
                .applyIfLet(border) { view, border in
                    view.overlay {
                        shape.strokeBorder(border.color, lineWidth: border.width)
                    }
                }.applyIfLet(shadow) { view, shadow in
                    view.shadow(shadow: shadow, shape: shape)
                }
        case .concave:
            // WIP: Need to implement
            content
                .modifier(ConcaveMaskModifier(curveHeightPercentage: 0.2))
        case .convex:
            content
                .modifier(ConvexMaskModifier(circleHeightPercentage: 0.2))
        }
    }

    func effectiveRectangleShape(radiusInfo: RadiusInfo?) -> AnyInsettableShape? {
        if let topLeft = radiusInfo?.topLeft,
           let topRight = radiusInfo?.topRight,
           let bottomLeft = radiusInfo?.bottomLeft,
           let bottomRight = radiusInfo?.bottomRight,
           topLeft > 0 || topRight > 0 || bottomLeft > 0 || bottomRight > 0 {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                UnevenRoundedRectangle(
                    topLeadingRadius: topLeft,
                    bottomLeadingRadius: bottomLeft,
                    bottomTrailingRadius: bottomRight,
                    topTrailingRadius: topRight,
                    style: .circular
                ).eraseToAnyInsettableShape()
            } else {
                BackportedUnevenRoundedRectangle(
                    topLeft: topLeft,
                    topRight: topRight,
                    bottomLeft: bottomLeft,
                    bottomRight: bottomRight
                ).eraseToAnyInsettableShape()
            }
        } else {
            nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct ConcaveMaskModifier: ViewModifier {

    let curveHeightPercentage: CGFloat

    @State
    private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onSizeChange { self.size = $0 }
            .clipShape(
                ConcaveShape(curveHeightPercentage: curveHeightPercentage, size: size)
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct ConcaveShape: Shape {

    let curveHeightPercentage: CGFloat
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at the top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Create the upward-facing concave curve
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY - proportionalCurveHeight)
        )

        // Bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        path.closeSubpath()

        return path
    }

    private var proportionalCurveHeight: CGFloat {
        // Calculate the curve height as a proportion of both width and height
        let baseHeight = size.height * curveHeightPercentage
        let widthFactor = size.width / size.height
        return baseHeight * widthFactor
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct ConvexMaskModifier: ViewModifier {

    let circleHeightPercentage: CGFloat

    @State
    private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onSizeChange { self.size = $0 }
            .clipShape(
                Circle()
                    .scale(self.circleScale)
                    .offset(y: self.circleOffset)
            )
    }

    private var circleScale: CGFloat {
        // Scale the circle such that its convex part matches the height percentage
        guard size.height > 0 else { return 1.0 }
        return 2 * (1.0 + self.circleHeightPercentage) * (size.width / size.height)
    }

    private var circleOffset: CGFloat {
        return (((self.size.height * self.circleScale) - self.size.height) / 2.0 * -1)
            .rounded(.down)
    }

}

// Type-erasing wrapper for InsettableShape protocol
struct AnyInsettableShape: InsettableShape {
    private var base: any InsettableShape

    init<S: InsettableShape>(_ shape: S) {
        self.base = shape
    }

    func path(in rect: CGRect) -> Path {
        base.path(in: rect)
    }

    func inset(by amount: CGFloat) -> AnyInsettableShape {
        var copy = self
        copy.base = copy.base.inset(by: amount)
        return copy
    }
}

private extension InsettableShape {
    func eraseToAnyInsettableShape() -> AnyInsettableShape {
        AnyInsettableShape(self)
    }
}

// Substitute for UnevenRoundedRectangle which is only available on iOS 16+
private struct BackportedUnevenRoundedRectangle: InsettableShape {
    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Adjust rect for insets
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Adjust corner radii for insets
        let adjustedTopLeft = max(0, topLeft - insetAmount)
        let adjustedTopRight = max(0, topRight - insetAmount)
        let adjustedBottomLeft = max(0, bottomLeft - insetAmount)
        let adjustedBottomRight = max(0, bottomRight - insetAmount)

        // Start from the top-left corner
        path.move(to: CGPoint(x: insetRect.minX + adjustedTopLeft, y: insetRect.minY))

        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: insetRect.maxX - adjustedTopRight, y: insetRect.minY))
        path.addArc(center: CGPoint(x: insetRect.maxX - adjustedTopRight, y: insetRect.minY + adjustedTopRight),
                    radius: adjustedTopRight,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)

        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - adjustedBottomRight))
        path.addArc(center: CGPoint(x: insetRect.maxX - adjustedBottomRight, y: insetRect.maxY - adjustedBottomRight),
                    radius: adjustedBottomRight,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)

        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: insetRect.minX + adjustedBottomLeft, y: insetRect.maxY))
        path.addArc(center: CGPoint(x: insetRect.minX + adjustedBottomLeft, y: insetRect.maxY - adjustedBottomLeft),
                    radius: adjustedBottomLeft,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)

        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + adjustedTopLeft))
        path.addArc(center: CGPoint(x: insetRect.minX + adjustedTopLeft, y: insetRect.minY + adjustedTopLeft),
                    radius: adjustedTopLeft,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func shape(
        border: ShapeModifier.BorderInfo?,
        shape: ShapeModifier.Shape?,
        shadow: ShadowModifier.ShadowInfo? = nil,
        background: BackgroundStyle? = nil,
        uiConfigProvider: UIConfigProvider? = nil
    ) -> some View {
        self.modifier(
            ShapeModifier(
                border: border,
                shape: shape,
                shadow: shadow,
                background: background,
                uiConfigProvider: uiConfigProvider
            )
        )
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CornerBorder_Previews: PreviewProvider {

    static func previewName(shape: ShapeModifier.Shape? = nil,
                            border: ShapeModifier.BorderInfo? = nil,
                            shadow: ShadowModifier.ShadowInfo? = nil,
                            background: BackgroundStyle? = nil) -> String {
        var name: [String] = []
        switch shape {
        case .pill: name.append("Pill")
        case .circle: name.append("Circle")
        case .rectangle: name.append("Rectangle")
        case .none, .concave, .convex: break
        }

        if border != nil { name.append("Border") }
        if shadow != nil { name.append("Shadow") }

        switch background {
        case .color: name.append("Color")
        case .image: name.append("Image")
        case .none: break
        }

        return name.joined(separator: " - ")
    }

    static let lightUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

    static var previews: some View {
        let shapes: [ShapeModifier.Shape?] = [
            .pill,
            .rectangle(.init(topLeft: 0, topRight: 5, bottomLeft: 10, bottomRight: 0)),
            nil
        ]

        let borders: [ShapeModifier.BorderInfo?] = [
            .init(color: .black, width: 1),
            nil
        ]

        let backgrounds: [BackgroundStyle?] = [
            .color(.init(light: .hex("#FFDE2180"))),
            .color(
                .init(
                    light: .linear(30, [
                        .init(color: "#000055", percent: 0),
                        .init(color: "#ffffff", percent: 100)
                    ])
                  )
             ),
            .image(.init(
                light: .init(
                    width: 750,
                    height: 530,
                    original: lightUrl,
                    heic: lightUrl,
                    heicLowRes: lightUrl
                )
            )),
            nil
        ]

        let shadows: [ShadowModifier.ShadowInfo?] = [
            .init(color: .black, radius: 3, x: 2, y: 2),
            nil
        ]

        ForEach(backgrounds, id: \.self) { background in
            VStack {
                ForEach(shapes, id: \.self) { shape in
                    ForEach(borders, id: \.self) { border in
                        ForEach(shadows, id: \.self) { shadow in
                            VStack {
                                Text(previewName(shape: shape, border: border, shadow: shadow))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                            }
                            .shape(border: border,
                                   shape: shape,
                                   shadow: shadow,
                                   background: background,
                                   uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
                            )
                            .padding(5)
                        }
                    }
                }
            }
            .background(.blue)
            .previewLayout(.sizeThatFits)
            .previewDisplayName(previewName(background: background))
        }

        // Equal Radius - No Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: nil,
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 8,
                                            bottomLeft: 8,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Equal Radius - No Border")

        // No - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 4),
                    shape: nil)
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("No Right - Blue Border")

        // Top Left and Bottom Right Radius - No Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: nil,
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 0,
                                            bottomLeft: 0,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Top Left and Bottom Right Radius - No Border")

        // Equal Radius - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 6),
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 8,
                                            bottomLeft: 8,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Equal Radius - Blue Border")

        // Top Left and Bottom Right Radius - Blue Border
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .shape(
                    border: .init(color: .blue,
                                  width: 6),
                    shape: .rectangle(.init(topLeft: 8,
                                            topRight: 0,
                                            bottomLeft: 0,
                                            bottomRight: 8)))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Top Left and Bottom Right - Blue Border")
    }
}

#endif

#endif
