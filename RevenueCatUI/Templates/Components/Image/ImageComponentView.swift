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

    let viewModel: ImageComponentViewModel

    var body: some View {
        RemoteImage(url: viewModel.url) { (image, size) in
            renderImage(image, size)
        }
        .size(viewModel.size)
        .clipped()
    }

    private func renderImage(_ image: Image, _ size: CGSize) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: viewModel.contentMode)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: viewModel.gradientColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shape(border: nil,
                   shape: viewModel.shape)
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
                    localizedStrings: [:],
                    component: .init(
                        source: .init(
                            light: .init(
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
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fit")

        // Light - Fill
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizedStrings: [:],
                    component: .init(
                        source: .init(
                            light: .init(
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
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Fill")

        // Light - Gradient
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizedStrings: [:],
                    component: .init(
                        source: .init(
                            light: .init(
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
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Gradient")

        // Light - Fit with Rounded Corner
        VStack {
            ImageComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizedStrings: [:],
                    component: .init(
                        source: .init(
                            light: .init(
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
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Light - Rounded Corner")
    }
}

#endif

#endif
