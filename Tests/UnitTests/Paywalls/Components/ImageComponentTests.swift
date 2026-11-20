//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/25.

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class ImageComponentTests: TestCase {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testPlaceholderSelection() throws {
        let webp = "https://example.com/low.webp"
        let urls = try self.imageURLs(candidate: webp)
        #if os(iOS)
        XCTAssertEqual(urls.placeholderURL.absoluteString, webp)
        XCTAssertEqual(urls.resized(width: 2, height: 3).placeholderURL.absoluteString, webp)
        #else
        XCTAssertEqual(urls.placeholderURL, urls.heicLowRes)
        #endif

        let config = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [.image(.init(source: .init(light: urls)))]),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#ffffff")))
        )
        XCTAssertEqual(config.allImageURLs, [urls.placeholderURL])

        #if os(iOS)
        let media = try XCTUnwrap(config.allCacheAssets.images.first)
        XCTAssertEqual(media.cachedAlternativeURL, urls.heicLowRes)
        XCTAssertTrue(media.imageSourcesToDownload { $0 == urls.heicLowRes }.isEmpty)
        #endif
        XCTAssertEqual(urls.heic.absoluteString, "https://example.com/full.heic")
        XCTAssertEqual(try urls.encodeAndDecode(), urls)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testInvalidOrMissingWebPUsesLegacyHEIC() throws {
        for candidate: Any? in [nil, NSNull(), 1, "", "relative.webp", "http://example.com/low.webp"] {
            let urls = try self.imageURLs(candidate: candidate)
            XCTAssertEqual(urls.placeholderURL, urls.heicLowRes)
            XCTAssertNil(urls.cachedAlternativeURL)
        }
    }

    private func imageURLs(candidate: Any?) throws -> PaywallComponent.ImageUrls {
        var json: [String: Any] = [
            "width": 10, "height": 20, "original": "https://example.com/full.png",
            "heic": "https://example.com/full.heic", "heic_low_res": "https://example.com/legacy.heic"
        ]
        json["webp_low_res"] = candidate
        return try JSONDecoder.default.decode(
            PaywallComponent.ImageUrls.self,
            from: JSONSerialization.data(withJSONObject: json)
        )
    }

    func testCodable() throws {
        let jsonData = try JsonLoader.data(for: "ImageComponent")

        // Validate decoding works
        let image = try JSONDecoder.default
            .decode(PaywallComponent.ImageComponent.self, from: jsonData)

        // validate encoding
        let image2 = try image.encodeAndDecode()

        // Validate some data
        XCTAssertEqual(
            image.source.light.original.absoluteString,
            "https://assets.revenuecat.com/_caaaattss_original_.png"
        )
        XCTAssertNil(image.source.dark)
        XCTAssertNotNil(image.colorOverlay)
        XCTAssertEqual(image.fitMode, PaywallComponent.FitMode.fill)
        XCTAssertNotNil(image.maskShape)
        XCTAssertNotNil(image.shadow)
        XCTAssertNotNil(image.size)
        XCTAssertEqual(image, image2)

    }
}
