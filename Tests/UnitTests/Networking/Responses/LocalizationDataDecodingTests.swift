//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizationDataDecodingTests.swift

@_spi(Internal) @testable import RevenueCat
import XCTest

class LocalizationDataDecodingTests: TestCase {

    func testDecodesString() throws {
        let json = #""hello world""#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let result = try JSONDecoder.default.decode(PaywallComponentsData.LocalizationData.self, from: data)
        XCTAssertEqual(result, .string("hello world"))
    }

    func testDecodesImage() throws {
        let json = """
        {
            "light": {
                "original": "https://assets.revenuecat.com/img.png",
                "heic": "https://assets.revenuecat.com/img.heic",
                "heic_low_res": "https://assets.revenuecat.com/img_low.heic",
                "width": 100,
                "height": 200
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let result = try JSONDecoder.default.decode(PaywallComponentsData.LocalizationData.self, from: data)
        guard case .image(let urls) = result else {
            XCTFail("Expected .image, got \(result)")
            return
        }
        XCTAssertEqual(urls.light.heicLowRes.absoluteString, "https://assets.revenuecat.com/img_low.heic")
    }

    func testDecodesVideo() throws {
        let json = """
        {
            "light": {
                "url": "https://assets.revenuecat.com/video.mp4",
                "url_low_res": "https://assets.revenuecat.com/video_low.mp4",
                "width": 1920,
                "height": 1080
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let result = try JSONDecoder.default.decode(PaywallComponentsData.LocalizationData.self, from: data)
        guard case .video(let urls) = result else {
            XCTFail("Expected .video, got \(result)")
            return
        }
        XCTAssertEqual(urls.light.url.absoluteString, "https://assets.revenuecat.com/video.mp4")
        XCTAssertEqual(urls.light.urlLowRes?.absoluteString, "https://assets.revenuecat.com/video_low.mp4")
        XCTAssertNil(urls.dark)
    }

    func testVideoDoesNotCrashLocalizationDictionaryDecode() throws {
        let json = """
        {
            "en_US": {
                "text_key": "Hello",
                "video_key": {
                    "light": {
                        "url": "https://assets.revenuecat.com/video.mp4",
                        "url_low_res": "https://assets.revenuecat.com/video_low.mp4",
                        "width": 1920,
                        "height": 1080
                    }
                }
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let result = try JSONDecoder.default.decode(
            [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary].self,
            from: data
        )
        let locale = try XCTUnwrap(result["en_US"])
        XCTAssertEqual(locale["text_key"], .string("Hello"))
        guard case .video(let urls) = locale["video_key"] else {
            XCTFail("Expected .video for video_key, got \(String(describing: locale["video_key"]))")
            return
        }
        XCTAssertEqual(urls.light.url.absoluteString, "https://assets.revenuecat.com/video.mp4")
    }
}
