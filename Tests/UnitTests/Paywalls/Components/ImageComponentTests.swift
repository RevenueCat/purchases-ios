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
@testable import RevenueCat
import XCTest

class ImageComponentTests: TestCase {

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
            "https://assets.pawwalls.com/1151049_1732039548.png"
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
