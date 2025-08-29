//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ShadowModifier.swift
//
//  Created by Jay Shortway on 31/10/2024.

import Foundation
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ShadowModifier: ViewModifier {

    struct ShadowInfo: Hashable {

        let color: Color
        let radius: CGFloat
        // swiftlint:disable:next identifier_name
        let x: CGFloat
        // swiftlint:disable:next identifier_name
        let y: CGFloat

        // swiftlint:disable:next identifier_name
        init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }

    }

    let shadow: ShadowInfo?
    let shape: (any Shape)?

    func body(content: Content) -> some View {
        #if !os(watchOS)
        if let shadow {
            if #available(macOS 14.0, *) {
                content
                    .background {
                        GeometryReader { geometry in
                            let rect = geometry.frame(in: .local)
                            LayerShadowView(shape: shape ?? Rectangle(),
                                            color: shadow.color,
                                            xOffset: shadow.x,
                                            yOffset: shadow.y,
                                            blur: shadow.radius * 2,
                                            spread: 0,
                                            rect: rect)
                            #if os(macOS) && DEBUG
                            // On macOS, CALayer shadows are not rendered properly using the
                            // default emerge rendering techniques
                            .emergeRenderingMode(.window)
                            #endif
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
            } else {
                // Fallback to default shadow on older versions of macOS where CGPath conversion for
                // NSBezierPath is unavailable.
                content.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func shadow(
        shadow: ShadowModifier.ShadowInfo?,
        shape: (some Shape)?
    ) -> some View {
        self.modifier(ShadowModifier(
            shadow: shadow,
            shape: shape
        ))
    }
}

#if !os(watchOS)

// Using the .shadow() modifier to add a drop shadow in SwiftUI has multiple downsides:
// - The shadow is applied to all children views (can be worked around with .compositingGroup())
// - The `.compositingGroup()` workaround stops working if the view has less than 100% opacity.
// - The shadow inherits the opacity of the view, making it impossible to have a translucent
//   or transparent view with a 100% opacity shadow.
//
// LayerShadowView tries to work around these limitations by rendering the shadow in a backing UIView,
// and using a Shape to mask off the inner part of the shadow.

#if canImport(UIKit)

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
private struct LayerShadowView: UIViewRepresentable {
    let shape: any Shape
    let color: Color
    let xOffset: CGFloat
    let yOffset: CGFloat
    let blur: CGFloat
    let spread: CGFloat
    let rect: CGRect

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.applyShadow(shape: shape,
                               color: color,
                               xOffset: xOffset,
                               yOffset: yOffset,
                               blur: blur,
                               spread: spread,
                               rect: rect)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.layer.applyShadow(shape: shape,
                                 color: color,
                                 xOffset: xOffset,
                                 yOffset: yOffset,
                                 blur: blur,
                                 spread: spread,
                                 rect: rect)
    }
}

#elseif canImport(AppKit)

@available(macOS 14.0, *)
@available(iOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private struct LayerShadowView: NSViewRepresentable {
    let shape: any Shape
    let color: Color
    let xOffset: CGFloat
    let yOffset: CGFloat
    let blur: CGFloat
    let spread: CGFloat
    let rect: CGRect

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.applyShadow(shape: shape,
                                color: color,
                                xOffset: xOffset,
                                yOffset: -yOffset, // Coordinate space is reversed in AppKit
                                blur: blur,
                                spread: spread,
                                rect: rect)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.applyShadow(shape: shape,
                                  color: color,
                                  xOffset: xOffset,
                                  yOffset: -yOffset, // Coordinate space is reversed in AppKit
                                  blur: blur,
                                  spread: spread,
                                  rect: rect)
    }
}

#endif

private extension CALayer {

    @available(iOS 15.0, macOS 14.0, tvOS 15.0, watchOS 8.0, *)
    // swiftlint:disable:next function_parameter_count
    func applyShadow(shape: any Shape,
                     color: Color,
                     xOffset: CGFloat,
                     yOffset: CGFloat,
                     blur: CGFloat,
                     spread: CGFloat,
                     rect: CGRect) {
        self.shadowColor = PlatformColor(color).cgColor
        self.shadowOpacity = 1
        self.shadowOffset = CGSize(width: xOffset, height: yOffset)
        self.shadowRadius = blur / 2

        // Create path for the shape
        let path = shape.path(in: rect)
        let shadowPath = path.cgPath

        // Create expanded path for shadow with spread
        let expandedRect = rect.insetBy(dx: -spread, dy: -spread)
        let expandedPath = shape.path(in: expandedRect).cgPath
        self.shadowPath = expandedPath

        // Create mask to cut out inner shape
        let maskRect = rect.insetBy(dx: -spread - blur * 2 - abs(xOffset),
                                    dy: -spread - blur * 2 - abs(yOffset))
        let maskPath = PlatformBezierPath(rect: maskRect)
        let innerPath = PlatformBezierPath(cgPath: shadowPath)
        maskPath.append(innerPath.reversing())

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        self.mask = maskLayer
    }
}

#endif

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Shadow_Previews: PreviewProvider {

    static var previews: some View {
        // Black, no offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 0), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, no offset")

        // Black, no offset, no background
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 0), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, no offset, no background")

        // Blue, no offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.blue, radius: 10, x: 0, y: 0), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Blue, no offset")

        // Black, x offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 20, y: 0), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, x offset")

        // Black, y offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 20), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, y offset")

        // Black, x & y offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 20, y: 20), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, x & y offset")

        // Black, 0 radius, x & y offset
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .shadow(shadow: .init(color: Color.black, radius: 0, x: 20, y: 20), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, 0 radius, x & y offset")

        // Black, 20% opacity
        VStack {
            Text("Hello")
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.yellow)
                .compositingGroup()
                .opacity(0.2)
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 0), shape: Rectangle())
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, 20% opacity")

    }
}

#endif

#endif
