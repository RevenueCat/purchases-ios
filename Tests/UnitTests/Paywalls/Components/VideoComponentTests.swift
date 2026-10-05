//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoComponentTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/15/25.

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class VideoComponentTests: TestCase {

    func testCodable() throws {
        let jsonData = try JsonLoader.data(for: "VideoComponent")

        // Validate decoding works
        let video: PaywallComponent.VideoComponent = try JSONDecoder.default
            .decode(PaywallComponent.VideoComponent.self, from: jsonData)

        // validate encoding
        let video2 = try video.encodeAndDecode()

        // Validate some data
        XCTAssertEqual(
            video.source.light.url.absoluteString,
            "https://RevenueCat.com/video-files/herding_cats.mp4"
        )
        XCTAssertNil(video.source.dark)
        XCTAssertNotNil(video.colorOverlay)
        XCTAssertNotNil(video.fallbackSource)
        XCTAssertEqual(video.fitMode, PaywallComponent.FitMode.fill)
        XCTAssertTrue(video.loop)
        XCTAssertNotNil(video.maskShape)
        XCTAssertTrue(video.muteAudio)
        XCTAssertNotNil(video.shadow)
        XCTAssertFalse(video.showControls)
        XCTAssertNotNil(video.size)
        XCTAssertEqual(video.overrideVideoLid, "abc123")
        XCTAssertEqual(video, video2)

    }

    func testDecodesWithoutOverrideVideoLid() throws {
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JsonLoader.data(for: "VideoComponent")) as? [String: Any]
        )
        json.removeValue(forKey: "override_video_lid")

        let video = try JSONDecoder.default.decode(
            PaywallComponent.VideoComponent.self,
            from: try JSONSerialization.data(withJSONObject: json)
        )

        XCTAssertNil(video.overrideVideoLid)
    }

    func testIgnoresOverrideSourceLid() throws {
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JsonLoader.data(for: "VideoComponent")) as? [String: Any]
        )
        json.removeValue(forKey: "override_video_lid")
        json["override_source_lid"] = "abc123"

        let video = try JSONDecoder.default.decode(
            PaywallComponent.VideoComponent.self,
            from: try JSONSerialization.data(withJSONObject: json)
        )

        XCTAssertNil(video.overrideVideoLid)
    }

    func testPartialDecodesOverrideVideoLid() throws {
        let json = """
        {
          "override_video_lid": "partial_lid",
          "source": \(Self.videoJSON)
        }
        """

        let partial = try JSONDecoder.default.decode(
            PaywallComponent.PartialVideoComponent.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(partial.overrideVideoLid, "partial_lid")
        XCTAssertEqual(partial, try partial.encodeAndDecode())
    }

    func testDifferentOverrideVideoLidsAreNotEqual() {
        let source = Self.videoUrls
        let first = PaywallComponent.VideoComponent(source: source, overrideVideoLid: "a")
        let second = PaywallComponent.VideoComponent(source: source, overrideVideoLid: "b")

        XCTAssertNotEqual(first, second)
    }

}

class VideoLocalizationsTests: TestCase {

    func testLocalizationDataDoesNotDecodeVideoValue() {
        XCTAssertThrowsError(
            try JSONDecoder.default.decode(
                PaywallComponentsData.LocalizationData.self,
                from: Data(VideoComponentTests.videoJSON.utf8)
            )
        )
    }

}

private extension VideoComponentTests {

    static let videoJSON = """
    {
      "light": {
        "width": 200,
        "height": 400,
        "url": "https://assets.revenuecat.com/video_es.mp4",
        "url_low_res": "https://assets.revenuecat.com/video_es_low_res.mp4"
      }
    }
    """

    static let videoUrls = PaywallComponent.ThemeVideoUrls(
        light: .init(
            width: 200,
            height: 400,
            url: URL(string: "https://assets.revenuecat.com/video_es.mp4")!,
            checksum: nil,
            urlLowRes: URL(string: "https://assets.revenuecat.com/video_es_low_res.mp4")!,
            checksumLowRes: nil
        ),
        dark: nil
    )

}
