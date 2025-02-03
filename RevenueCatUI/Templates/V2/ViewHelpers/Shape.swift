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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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
    var background: BackgroundStyle?
    var uiConfigProvider: UIConfigProvider?

    init(border: BorderInfo?,
         shape: Shape?,
         background: BackgroundStyle?,
         uiConfigProvider: UIConfigProvider?
    ) {
        self.border = border
        self.shape = shape ?? .rectangle(nil)
        self.background = background
        self.uiConfigProvider = uiConfigProvider
    }

    func body(content: Content) -> some View {
        switch self.shape {
        case .circle, .pill, .rectangle:
            if let shape = self.shape.toInsettableShape() {
                content
                    .backgroundStyle(background)
                // We want to clip only in case there is a non-Rectangle shape
                // or if there's a border, otherwise we let the background color
                // extend behind the safe areas
                    .applyIf(!shape.isRectangle()) { view in
                        view.clipShape(shape)
                    }
                    .applyIfLet(border) { view, border in
                        view.clipShape(shape).overlay {
                            shape.strokeBorder(border.color, lineWidth: border.width)
                        }
                    }
            }
        case .concave:
            // WIP: Need to implement
            content
                .modifier(ConcaveMaskModifier(curveHeightPercentage: 0.2))
        case .convex:
            content
                .modifier(ConvexMaskModifier(curveHeightPercentage: 0.2))
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
            control: CGPoint(x: rect.midX, y: rect.maxY - self.curveHeight)
        )

        // Bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        path.closeSubpath()

        return path
    }

    private var curveHeight: CGFloat {
        // Calculate the curve height as a percentage of the view's height
        max(0, size.height * curveHeightPercentage)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct ConvexMaskModifier: ViewModifier {

    let curveHeightPercentage: CGFloat

    @State
    private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onSizeChange { self.size = $0 }
            .clipShape(
                ConvexShape(curveHeightPercentage: curveHeightPercentage, size: size)
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct ConvexShape: Shape {

    let curveHeightPercentage: CGFloat
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at the top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - curveHeight))

        // Create the concave curve
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - curveHeight),
            control: CGPoint(x: rect.midX, y: rect.maxY + curveHeight)
        )

        // Bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - curveHeight))

        path.closeSubpath()

        return path
    }

    private var curveHeight: CGFloat {
        // Calculate the curve height as a percentage of the view's height
        max(0, size.height * curveHeightPercentage) / 2
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

    func isRectangle() -> Bool {
        base is Rectangle
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
        background: BackgroundStyle? = nil,
        uiConfigProvider: UIConfigProvider? = nil
    ) -> some View {
        self.modifier(
            ShapeModifier(
                border: border,
                shape: shape,
                background: background,
                uiConfigProvider: uiConfigProvider
            )
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension ShapeModifier.Shape {
    func toInsettableShape() -> (AnyInsettableShape)? {
        switch self {
        case .rectangle(let radiusInfo):
            return self.effectiveRectangleShape(radiusInfo: radiusInfo)
        case .circle:
            return Circle().eraseToAnyInsettableShape()
        case .pill:
            #if compiler(>=5.9)
            return Capsule(style: .circular).eraseToAnyInsettableShape()
            #else
            return Capsule().eraseToAnyInsettableShape()
            #endif
        case .concave, .convex:
            return nil
        }
    }

    private func effectiveRectangleShape(radiusInfo: ShapeModifier.RadiusInfo?) -> AnyInsettableShape {
        let topLeft = radiusInfo?.topLeft ?? 0
        let topRight = radiusInfo?.topRight ?? 0
        let bottomLeft = radiusInfo?.bottomLeft ?? 0
        let bottomRight = radiusInfo?.bottomRight ?? 0
        if  topLeft > 0 || topRight > 0 || bottomLeft > 0 || bottomRight > 0 {
            #if compiler(>=5.9)
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return UnevenRoundedRectangle(
                    topLeadingRadius: topLeft,
                    bottomLeadingRadius: bottomLeft,
                    bottomTrailingRadius: bottomRight,
                    topTrailingRadius: topRight,
                    style: .circular
                ).eraseToAnyInsettableShape()
            } else {
                return BackportedUnevenRoundedRectangle(
                    topLeft: topLeft,
                    topRight: topRight,
                    bottomLeft: bottomLeft,
                    bottomRight: bottomRight
                ).eraseToAnyInsettableShape()
            }
            #else
            return BackportedUnevenRoundedRectangle(
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight
            ).eraseToAnyInsettableShape()
            #endif
        } else {
            return Rectangle().eraseToAnyInsettableShape()
        }
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
                                   background: background,
                                   uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
                            )
                            .shadow(shadow: shadow, shape: shape?.toInsettableShape())
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
