//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackgroundStyle.swift
//
//  Created by Josh Holtz on 11/20/24.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

enum BackgroundStyle {

    case color(PaywallComponent.ColorScheme)
    case image(PaywallComponent.ThemeImageUrls)
    case gradient

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BackgroundStyleModifier: ViewModifier {

    var backgroundStyle: BackgroundStyle?

    func body(content: Content) -> some View {
        if let backgroundStyle {
            content
                .apply(backgroundStyle: backgroundStyle)
        } else {
            content
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {

    @ViewBuilder
    func apply(backgroundStyle: BackgroundStyle) -> some View {
        switch backgroundStyle {
        case .color(let color):
            self.background(color.toDynamicColor())
        case .image(let imageInfo):
            self.background {
                RemoteImage(
                    url: imageInfo.light.heic,
                    lowResUrl: imageInfo.light.heicLowRes,
                    darkUrl: imageInfo.dark?.heic,
                    darkLowResUrl: imageInfo.dark?.heicLowRes
                ) { (image, _) in
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
        case .gradient:
            self.background {
                // WIP: Add you gradient
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func backgroundStyle(_ backgroundStyle: BackgroundStyle?) -> some View {
        self.modifier(BackgroundStyleModifier(backgroundStyle: backgroundStyle))
    }

}

extension PaywallComponent.Background {

    var backgroundStyle: BackgroundStyle? {
        switch self {
        case .color(let value):
            return .color(value)
        case .image(let value):
            return .image(value)
        }
    }

}

extension PaywallComponent.ColorScheme {

    var backgroundStyle: BackgroundStyle {
        return .color(self)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BackgrounDStyle_Previews: PreviewProvider {

    static let lightUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let darkUrl = URL(string: "https://assets.pawwalls.com/954459_1710750526.jpeg")!

    static var testContent: some View {
        ZStack(alignment: .center) {
            Text("Text")
                .padding()
                .foregroundStyle(.black)
                .background(.white)
                .cornerRadius(8)
        }
        .frame(width: 200, height: 200)
    }

    static var previews: some View {
        // Color - Light (should be red)
        testContent
            .backgroundStyle(.color(.init(
                light: .hex("#ff0000"),
                dark: .hex("#ffcc00")
            )))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Color - Light (should be red)")

        // Color - Dark (should be red)
        testContent
            .backgroundStyle(.color(.init(
                light: .hex("#ff0000"),
                dark: .hex("#ffcc00")
            )))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Color - Dark (should be yellow)")

        // Color - Dark (should be red because fallback)
        testContent
            .backgroundStyle(.color(.init(
                light: .hex("#ff0000")
            )))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Color - Dark (should be red because fallback)")

        // Image - Light (should be pink cat)
        testContent
            .backgroundStyle(.image(.init(
                light: .init(
                    original: lightUrl,
                    heic: lightUrl,
                    heicLowRes: lightUrl
                ),
                dark: .init(
                    original: darkUrl,
                    heic: darkUrl,
                    heicLowRes: darkUrl
                )
            )))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Image - Light (should be pink cat)")

        // Image - Dark (should be japan cats)
        testContent
            .backgroundStyle(.image(.init(
                light: .init(
                    original: lightUrl,
                    heic: lightUrl,
                    heicLowRes: lightUrl
                ),
                dark: .init(
                    original: darkUrl,
                    heic: darkUrl,
                    heicLowRes: darkUrl
                )
            )))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Image - Dark (should be japan cats)")
    }
}

#endif

#endif
