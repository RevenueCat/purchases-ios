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

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IconComponentView: View {

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

    let viewModel: IconComponentViewModel

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            )
        ) { style in
            RemoteImage(
                url: style.url
            ) { (image, size) in
                self.renderImage(image, size, with: style)
            }
            .size(style.size)
            .clipped()
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

        // Light - Fit
        VStack {
            IconComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        baseUrl: "https://paywall-icons.s3.us-east-1.amazonaws.com/icons",
                        iconName: "star-off",
                        formats: .init(
                            svg: "star-off.svg",
                            png: "star-off.png",
                            heic: "star-off.heic",
                            webp: "star-off.webp"
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
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 100, height: 100))
        .previewDisplayName("Default")

    }
}

#endif

#endif
