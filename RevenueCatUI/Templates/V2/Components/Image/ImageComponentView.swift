//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.colorScheme)
    private var colorScheme

    let viewModel: ImageComponentViewModel

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            )
        ) { style in
            if style.visible {
                RemoteImage(
                    url: style.url,
                    lowResUrl: style.lowResUrl,
                    darkUrl: style.darkUrl,
                    darkLowResUrl: style.darkLowResUrl
                ) { (image, size) in
                    self.renderImage(image, size, with: style)
                }
                .size(style.size)
                .clipped()
                .padding(style.padding.extend(by: style.border?.width ?? 0))
                .shape(border: style.border,
                       shape: style.shape)
                .shadow(shadow: style.shadow,
                        shape: style.shape?.toInsettableShape())
                .padding(style.margin)
            }
        }
    }

    private func aspectRatio(style: ImageComponentStyle) -> Double {
        let (width, height) = self.imageSize(style: style)
        return Double(width) / Double(height)
    }

    private func imageSize(style: ImageComponentStyle) -> (width: Int, height: Int) {
        switch self.colorScheme {
        case .light:
            return (style.widthLight, style.heightLight)
        case .dark:
            return (style.widthDark ?? style.widthLight, style.heightDark ?? style.heightLight)
        @unknown default:
            return (style.widthLight, style.heightLight)
        }
    }

    private func renderImage(_ image: Image, _ size: CGSize, with style: ImageComponentStyle) -> some View {
        image
            .fitToAspect(
                self.aspectRatio(style: style),
                contentMode: style.contentMode,
                containerContentMode: style.contentMode
            )
            .frame(maxWidth: .infinity)
            // WIP: Fix this later when accessibility info is available
            .accessibilityHidden(true)
            .applyIfLet(style.colorOverlay, apply: { view, colorOverlay in
                view.overlay(
                    Color.clear.backgroundStyle(.color(colorOverlay))
                )
            })
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_body_length
struct ImageComponentView_Previews: PreviewProvider {
    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {
        // Light - Fit
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fit,
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fit")

        // Light - Fill
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fill,
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fill")

        // Light - Gradient
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fill,
                        colorOverlay: .init(light: .linear(0, [
                            .init(color: "#ffffff", percent: 0),
                            .init(color: "#ffffff00", percent: 40)
                        ])),
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Gradient")

        // Light - Fit with Rounded Corner
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fit,
                        maskShape: .rectangle(.init(topLeading: 40,
                                                    topTrailing: 40,
                                                    bottomLeading: 40,
                                                    bottomTrailing: 40)),
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Rounded Corner")

        // Light - Fit with Circle
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fit,
                        maskShape: .circle,
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Circle")

        // Light - Fit with Convex
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fit,
                        maskShape: .convex,
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fit with Convex")

        // Light - Fit with Concave
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        source: .init(
                            light: .init(
                                width: 750,
                                height: 530,
                                original: catUrl,
                                heic: catUrl,
                                heicLowRes: catUrl
                            )
                        ),
                        fitMode: .fit,
                        maskShape: .concave,
                        border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                        shadow: .init(
                            color: .init(
                                light: .hex("#000000"),
                                dark: .hex("#000000")
                            ),
                            radius: 5, x: 5, y: 5
                        )
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fit with Concave")
    }
}

#endif

#endif
