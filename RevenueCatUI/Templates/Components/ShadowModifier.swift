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

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ShadowModifier: ViewModifier {

    struct ShadowInfo {

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

    var shadow: ShadowInfo

    func body(content: Content) -> some View {
        content
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func shadow(
        shadow: ShadowModifier.ShadowInfo
    ) -> some View {
        self.modifier(ShadowModifier(shadow: shadow))
    }
}

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
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 0))
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
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 0))
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
                .shadow(shadow: .init(color: Color.blue, radius: 10, x: 0, y: 0))
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
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 20, y: 0))
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
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 0, y: 20))
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
                .shadow(shadow: .init(color: Color.black, radius: 10, x: 20, y: 20))
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
                .shadow(shadow: .init(color: Color.black, radius: 0, x: 20, y: 20))
                .padding()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Black, 0 radius, x & y offset")

    }
}

#endif

#endif
