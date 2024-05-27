//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateBackgroundImageView.swift
//  
//  Created by Nacho Soto on 8/1/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TemplateBackgroundImageView: View {

    private let url: URL?
    private let urlLowRes: URL?
    private let blurred: Bool
    private let ignoreSafeArea: Bool

    init(configuration: TemplateViewConfiguration) {
        self.init(url: configuration.backgroundImageURLToDisplay,
                  lowResUrl: configuration.backgroundLowResImageToDisplay,
                  blurred: configuration.configuration.blurredBackgroundImage)
    }

    init(url: URL?, lowResUrl: URL?, blurred: Bool, ignoreSafeArea: Bool = true) {
        self.url = url
        self.urlLowRes = lowResUrl
        self.blurred = blurred
        self.ignoreSafeArea = ignoreSafeArea
    }

    var body: some View {
        if let url = self.url {
            let image = self.image(url, lowResUrl: self.urlLowRes)
                .unredacted()

            if self.ignoreSafeArea {
                image
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                image
            }
        }
    }

    @ViewBuilder
    private func image(_ url: URL, lowResUrl: URL?) -> some View {
        if self.blurred {
            RemoteImage(url: url, lowResUrl: lowResUrl)
                .blur(radius: 40)
                .opacity(0.7)
                .background {
                    // Simulate dark materials in pre-watchOS 10.0
                    // where `Material` isn't available.
                    #if os(watchOS)
                    if #unavailable(watchOS 10.0) {
                        Color.black
                    }
                    #endif
                }
        } else {
            RemoteImage(url: url, lowResUrl: lowResUrl)
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct TemplateBackgroundImageView_Previews: PreviewProvider {

    static var previews: some View {
        TemplateBackgroundImageView(
            url: TestData.paywallAssetBaseURL.appendingPathComponent(TestData.paywallHeaderImageName),
            lowResUrl: nil,
            blurred: false
        )
        .previewDisplayName("Wrong aspect ratio not blured")

        TemplateBackgroundImageView(
            url: TestData.paywallAssetBaseURL.appendingPathComponent(TestData.paywallHeaderImageName),
            lowResUrl: nil,
            blurred: true
        )
        .previewDisplayName("Wrong aspect ratio blured")

        TemplateBackgroundImageView(
            url: TestData.paywallAssetBaseURL.appendingPathComponent(TestData.paywallBackgroundImageName),
            lowResUrl: nil,
            blurred: false
        )
        .previewDisplayName("Correct aspect ratio not blured")

        TemplateBackgroundImageView(
            url: TestData.paywallAssetBaseURL.appendingPathComponent(TestData.paywallBackgroundImageName),
            lowResUrl: nil,
            blurred: true
        )
        .previewDisplayName("Correct aspect ratio blured")
    }

}

#endif
