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
            self
                .background(color.toDynamicColor())
        case .image(let imageInfo):
            ZStack {
                RemoteImage(
                    url: imageInfo.light.heic,
                    lowResUrl: imageInfo.light.heicLowRes,
                    darkUrl: imageInfo.dark?.heic,
                    darkLowResUrl: imageInfo.dark?.heicLowRes
                ) { (image, size) in
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }

                self
            }
        case .gradient:
            ZStack {
                // WIP: Gradient
                self
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

#endif
