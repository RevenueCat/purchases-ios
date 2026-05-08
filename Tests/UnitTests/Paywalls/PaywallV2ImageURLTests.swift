//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallV2ImageURLTests.swift

@_spi(Internal) @testable import RevenueCat
import XCTest

class PaywallV2ImageURLTests: TestCase {

    // MARK: - Localized image preloading

    func testLocalizedImagesAreIncludedInAllImageURLs() {
        let lightURL = URL(string: "https://assets.revenuecat.com/localized_light.heic")!
        let imageUrls = makeImageUrls(heicLowRes: lightURL)
        let localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary] = [
            "en_US": ["image_key": .image(.init(light: imageUrls))]
        ]

        let urls = makeData(localizations: localizations).allImageURLs
        XCTAssertTrue(urls.contains(lightURL), "Localized image URL should be preloaded")
    }

    func testLocalizedVideoDoesNotCrashAndIsIgnoredForImagePreloading() {
        let videoUrls = makeVideoUrls()
        let localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary] = [
            "en_US": ["video_key": .video(videoUrls)]
        ]

        let urls = makeData(localizations: localizations).allImageURLs
        XCTAssertTrue(urls.isEmpty, "Localized video should not contribute image URLs")
    }

    // MARK: - VideoComponent override fallback preloading

    func testVideoFallbackSourceIsPreloaded() {
        let lightURL = URL(string: "https://assets.revenuecat.com/fallback_light.heic")!
        let video = PaywallComponent.VideoComponent(
            source: makeVideoUrls(),
            fallbackSource: .init(light: makeImageUrls(heicLowRes: lightURL))
        )

        let urls = makeData(components: [.video(video)]).allImageURLs
        XCTAssertTrue(urls.contains(lightURL), "Video fallback source should be preloaded")
    }

    func testVideoOverrideFallbackSourceIsPreloaded() {
        let overrideURL = URL(string: "https://assets.revenuecat.com/override_fallback.heic")!
        let override = PaywallComponent.ComponentOverride(
            conditions: [.compact],
            properties: PaywallComponent.PartialVideoComponent(
                fallbackSource: .init(light: makeImageUrls(heicLowRes: overrideURL))
            )
        )
        let video = PaywallComponent.VideoComponent(
            source: makeVideoUrls(),
            overrides: [override]
        )

        let urls = makeData(components: [.video(video)]).allImageURLs
        XCTAssertTrue(urls.contains(overrideURL), "Video override fallback source should be preloaded")
    }

    func testVideoFallbackAndOverrideFallbackBothPreloaded() {
        let baseURL = URL(string: "https://assets.revenuecat.com/base_fallback.heic")!
        let overrideURL = URL(string: "https://assets.revenuecat.com/override_fallback.heic")!
        let override = PaywallComponent.ComponentOverride(
            conditions: [.compact],
            properties: PaywallComponent.PartialVideoComponent(
                fallbackSource: .init(light: makeImageUrls(heicLowRes: overrideURL))
            )
        )
        let video = PaywallComponent.VideoComponent(
            source: makeVideoUrls(),
            fallbackSource: .init(light: makeImageUrls(heicLowRes: baseURL)),
            overrides: [override]
        )

        let urls = makeData(components: [.video(video)]).allImageURLs
        XCTAssertTrue(urls.contains(baseURL), "Base fallback should be preloaded")
        XCTAssertTrue(urls.contains(overrideURL), "Override fallback should be preloaded")
    }

}

// MARK: - Helpers

private extension PaywallV2ImageURLTests {

    func makeImageUrls(heicLowRes: URL) -> PaywallComponent.ImageUrls {
        return .init(width: 100, height: 100, original: heicLowRes, heic: heicLowRes, heicLowRes: heicLowRes)
    }

    func makeVideoUrls() -> PaywallComponent.ThemeVideoUrls {
        let videoUrls = PaywallComponent.VideoUrls(
            width: 1920,
            height: 1080,
            url: URL(string: "https://assets.revenuecat.com/video.mp4")!,
            checksum: nil,
            urlLowRes: URL(string: "https://assets.revenuecat.com/video_low.mp4")!,
            checksumLowRes: nil
        )
        return .init(light: videoUrls)
    }

    func makeData(
        components: [PaywallComponent] = [],
        localizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary] = [:]
    ) -> PaywallComponentsData {
        return .init(
            templateName: "test",
            assetBaseURL: URL(string: "https://assets.revenuecat.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: components),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: localizations,
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

}
