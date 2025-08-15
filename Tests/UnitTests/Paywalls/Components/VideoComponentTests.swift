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
@testable import RevenueCat
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
            "https://videos.pexels.com/video-files/5532767/5532767-uhd_1440_2732_25fps.mp4"
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
        XCTAssertEqual(video, video2)

    }
}
