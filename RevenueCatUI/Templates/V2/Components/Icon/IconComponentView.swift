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
struct IconComponentView: View {

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

    let viewModel: IconComponentViewModel

    var body: some View {
        self.viewModel.styles(
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
                RemoteImage(
                    url: style.url,
                    // The expectedSize is important
                    // It renders a clear image if actual image is being fetched
                    expectedSize: self.viewModel.expectedSize
                ) { (image, size) in
                    self.renderImage(image, size, with: style)
                }
                .padding(style.padding.extend(by: style.iconBackgroundBorder?.width ?? 0))
                .shape(border: style.iconBackgroundBorder,
                       shape: style.iconBackgroundShape,
                       background: style.iconBackgroundStyle,
                       uiConfigProvider: self.viewModel.uiConfigProvider)
                .shadow(shadow: style.iconBackgroundShadow,
                        shape: style.iconBackgroundShape?.toInsettableShape())
                .padding(style.margin)
                .size(style.size)
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

    private func renderImage(_ image: Image, _ size: CGSize, with style: IconComponentStyle) -> some View {
        image
            .renderingMode(.template)
            .fitToAspect(
                1,
                contentMode: .fit,
                containerContentMode: .fit
            )
            .foregroundColor(style.color)
            .frame(maxWidth: .infinity)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IconComponentView_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Default
        VStack {
            IconComponentView(
                viewModel: .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        baseUrl: "https://icons.pawwalls.com/icons",
                        iconName: "pizza",
                        formats: .init(
                            svg: "pizza.svg",
                            png: "pizza.png",
                            heic: "pizza.heic",
                            webp: "pizza.webp"
                        ),
                        size: .init(width: .fixed(80), height: .fixed(80)),
                        padding: .zero,
                        margin: .zero,
                        color: .init(light: .hex("#ff0000")),
                        iconBackground: nil
                    )
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 100, height: 100))
        .previewDisplayName("Default")

        // Default - Background
        VStack {
            IconComponentView(
                viewModel: .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        baseUrl: "https://icons.pawwalls.com/icons",
                        iconName: "pizza",
                        formats: .init(
                            svg: "pizza.svg",
                            png: "pizza.png",
                            heic: "pizza.heic",
                            webp: "pizza.webp"
                        ),
                        size: .init(width: .fixed(150), height: .fixed(150)),
                        padding: .init(top: 20, bottom: 20, leading: 20, trailing: 20),
                        margin: .init(top: 20, bottom: 20, leading: 20, trailing: 20),
                        color: PaywallComponent.ColorScheme(
                            light: .hex("#ff0000")
                        ),
                        iconBackground: PaywallComponent.IconComponent.IconBackground(
                            color: .init(light: .hex("#ffcc00")),
                            shape: .circle,
                            border: .init(color: .init(light: .hex("#ff0000")), width: 5),
                            shadow: .init(color: .init(light: .hex("#33333399")), radius: 10, x: 5, y: 5)
                        )
                    )
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 200, height: 200))
        .previewDisplayName("Default - Background")

    }
}

#endif

#endif
