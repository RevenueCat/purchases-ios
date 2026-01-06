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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.colorScheme)
    private var colorScheme

    let viewModel: ImageComponentViewModel

    @State var size: CGSize?

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            ),
            colorScheme: colorScheme
        ) { style in
            if style.visible {
                let expectedSize = CGSize(
                    width: self.imageSize(style: style).width,
                    height: self.imageSize(style: style).height
                )

                ZStack {
                    // IMPORTANT: Please keep this... needed to force size
                    //
                    // We need the max width of the parent view an image of a fill or
                    // fixed width doesn't push passed the bounds.
                    //
                    // Once we have the size once, we can remove the Color.clear
                    if self.size == nil {
                        Color.clear
                    }

                    RemoteImage(
                        url: style.url,
                        lowResUrl: style.lowResUrl,
                        darkUrl: style.darkUrl,
                        darkLowResUrl: style.darkLowResUrl,
                        // The expectedSize is important
                        // It renders a clear image if actual image is being fetched
                        expectedSize: expectedSize
                    ) { (image, size) in
                        self.renderImage(
                            image,
                            size,
                            maxWidth: self.calculateMaxWidth(
                                parentWidth: self.size?.width ?? 0,
                                style: style
                            ),
                            with: style
                        )
                    }
                    .applyMediaWidth(size: style.size)
                    .applyMediaHeight(size: style.size, aspectRatio: self.aspectRatio(style: style))
                    .applyIfLet(style.colorOverlay, apply: { view, colorOverlay in
                        view.overlay(
                            Color.clear
                                .backgroundStyle(.color(colorOverlay))
                        )
                    })
                    .clipped()
                    .padding(style.padding.extend(by: style.border?.width ?? 0))
                    .shape(border: style.border,
                           shape: style.shape)
                    .applyIfLet(style.shadow, apply: { view, shadow in
                        // We need to use the normal shadow modifier and not our custom one for png images
                        view.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
                    })
                    .padding(style.margin)
                }
                .onSizeChange({ size = $0 })

            }
        }
    }

    private func calculateMaxWidth(parentWidth: CGFloat, style: ImageComponentStyle) -> CGFloat {
        let totalBorderWidth = (style.border?.width ?? 0) * 2
        let maxWidth = parentWidth - totalBorderWidth
            - style.margin.leading - style.margin.trailing
            - style.padding.leading - style.padding.trailing
        return max(0, maxWidth)
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

    private func renderImage(
        _ image: Image,
        _ size: CGSize,
        maxWidth: CGFloat,
        with style: ImageComponentStyle
    ) -> some View {
        image
            .fitToAspect(
                self.aspectRatio(style: style),
                contentMode: style.contentMode,
                containerContentMode: style.contentMode
            )
            .frame(maxWidth: maxWidth)
            // WIP: Fix this later when accessibility info is available
            .accessibilityHidden(true)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_body_length
struct ImageComponentView_Previews: PreviewProvider {
    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let bigImageUrl = URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!
    static let smallImage = URL(string: "https://assets.pawwalls.com/1172568_1734493671.heic")!

    @ViewBuilder
    static func imageView(
        url: URL,
        size: PaywallComponent.Size,
        fitMode: PaywallComponent.FitMode,
        width: Int,
        height: Int
    ) -> some View {
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
                            width: width,
                            height: height,
                            original: url,
                            heic: url,
                            heicLowRes: url
                        )
                    ),
                    size: size,
                    fitMode: fitMode,
                    border: .init(color: .init(light: .hex("#ff0000")), width: 4)
                )
            )
        )
        Text(.init("width: **\(size.width)** height: **\(size.height)**\n" +
                   "fitMode: **\(fitMode)**\n" +
                   "width: **\(width)** height: **\(height)**"))
    }

    static var fixedHeight: UInt = 360

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        ScrollView {
            VStack {
                imageView(url: bigImageUrl,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 1080, height: 599)

                imageView(url: smallImage,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 22, height: 21)
            }.background(.blue)
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Image stretching horizontally beyond bounds")

        ScrollView {
            VStack {
                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fit),
                              fitMode: .fill, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fit),
                              fitMode: .fit, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fill),
                              fitMode: .fill, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fill),
                              fitMode: .fit, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)
            }.background(.blue)
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Image streching vertically when height=fit")

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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
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
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fit with Concave")
    }
}

#endif

#endif
