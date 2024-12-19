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
            // WIP: Need to replace this gradient with the better one
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: style.gradientColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // WIP: this needs more shapes and borders
            // WIP: this might also need dropshadow
            .shape(border: nil,
                   shape: style.shape)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
                        fitMode: .fit
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
                        fitMode: .fill
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
                        gradientColors: [
                            "#ffffff00", "#ffffff00", "#ffffffff"
                        ]
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
                                                    bottomTrailing: 40))
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Rounded Corner")
    }
}

#endif

#endif
