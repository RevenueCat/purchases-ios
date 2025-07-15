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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
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
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor(color).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        view.layer.shadowRadius = blur / 2

        // Create path for the shape
        let path = shape.path(in: rect)
        let shadowPath = path.cgPath

        // Create expanded path for shadow with spread
        let expandedRect = rect.insetBy(dx: -spread, dy: -spread)
        let expandedPath = shape.path(in: expandedRect).cgPath
        view.layer.shadowPath = expandedPath

        // Create mask to cut out inner shape
        let maskRect = rect.insetBy(dx: -spread - blur * 2 - abs(xOffset),
                                    dy: -spread - blur * 2 - abs(yOffset))
        let maskPath = UIBezierPath(rect: maskRect)
        let innerPath = UIBezierPath(cgPath: shadowPath)
        maskPath.append(innerPath.reversing())

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        view.layer.mask = maskLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.layer.shadowColor = UIColor(color).cgColor
        uiView.layer.shadowOpacity = 1
        uiView.layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        uiView.layer.shadowRadius = blur / 2

        // Update shadow path
        let expandedRect = rect.insetBy(dx: -spread, dy: -spread)
        let expandedPath = shape.path(in: expandedRect).cgPath
        uiView.layer.shadowPath = expandedPath

        // Update mask
        let path = shape.path(in: rect)
        let shadowPath = path.cgPath

        let maskRect = rect.insetBy(dx: -spread - blur * 2 - abs(xOffset),
                                    dy: -spread - blur * 2 - abs(yOffset))
        let maskPath = UIBezierPath(rect: maskRect)
        let innerPath = UIBezierPath(cgPath: shadowPath)
        maskPath.append(innerPath.reversing())

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        uiView.layer.mask = maskLayer
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

    }
}

#endif

#endif
