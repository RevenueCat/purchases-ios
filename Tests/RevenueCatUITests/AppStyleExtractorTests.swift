//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppStyleExtractorTests.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

import Nimble
@testable import RevenueCatUI
import SwiftUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class AppStyleExtractorTests: TestCase {

    // MARK: - Color Extraction Accuracy Tests

    func testExtractsRedAndGreen_fromRedGreenImage() {
        let image = DualColorImageGenerator.redGreen.cgImage

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        expect(colors).to(haveCount(2))
        expect(colors).to(containColorNear(.red))
        expect(colors).to(containColorNear(.green))
    }

    func testExtractsBlueAndGreen_fromBlueGreenImage() {
        let image = DualColorImageGenerator.blueGreen.cgImage

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        expect(colors).to(haveCount(2))
        expect(colors).to(containColorNear(.blue))
        expect(colors).to(containColorNear(.green))
    }

    func testExtractsPurpleAndOrange_fromPurpleOrangeImage() {
        let image = DualColorImageGenerator.purpleOrange.cgImage

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        expect(colors).to(haveCount(2))
        expect(colors).to(containColorNear(.purple))
        expect(colors).to(containColorNear(.orange))
    }

    func testColorsAreDistinct() {
        let image = DualColorImageGenerator.redGreen.cgImage

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        expect(colors.count).to(beGreaterThanOrEqualTo(2))

        // Verify all returned colors have sufficient distance from each other
        for index in 0..<colors.count {
            for index2 in (index + 1)..<colors.count {
                let distance = colorDistance(colors[index], colors[index2])
                expect(distance).to(beGreaterThan(ColorExtractionConstants.minimumColorDistance),
                                    description: "Colors at indices \(index) and \(index) should be distinct")
            }
        }
    }

    // MARK: - Edge Case Tests

    func testReturnsEmptyArray_forNilImage() {
        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: nil)

        expect(colors).to(beEmpty())
    }

    func testFiltersTransparentPixels() {
        let image = DualColorImageGenerator.transparent()

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        expect(colors).to(beEmpty())
    }

    func testFiltersVeryDarkAndBrightColors() {
        let image = DualColorImageGenerator.blackWhite.cgImage

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image)

        // Black and white should be filtered out
        expect(colors).to(beEmpty())
    }

    func testSingleColorImage_extractsSingleColor() {
        // Use a medium saturated color that won't be filtered
        let testColor = Color(red: 0.8, green: 0.2, blue: 0.2)
        guard let image = DualColorImageGenerator.singleColor(testColor) else {
            fail("Failed to create single color image")
            return
        }

        let colors = AppStyleExtractor.extractProminentColorsForPreview(image: image.cgImage)

        // Single color image should extract that color (if it passes brightness filters)
        expect(colors.count).to(beLessThanOrEqualTo(1))
        if !colors.isEmpty {
            expect(colors).to(containColorNear(testColor))
        }
    }

    // MARK: - Helpers

    private func colorDistance(_ color1: Color, _ color2: Color) -> Double {
        let rgb1 = extractRGBComponents(from: color1)
        let rgb2 = extractRGBComponents(from: color2)

        let dred = rgb1.0 - rgb2.0
        let dgreen = rgb1.1 - rgb2.1
        let dblue = rgb1.2 - rgb2.2

        return sqrt(dred * dred + dgreen * dgreen + dblue * dblue)
    }
}

// MARK: - Custom Matchers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private func containColorNear(_ expectedColor: Color, tolerance: Double = 0.3) -> Nimble.Matcher<[Color]> {
    return Matcher { actualExpression in
        guard let colors = try actualExpression.evaluate() else {
            return MatcherResult(
                status: .fail,
                message: .fail("expected colors array, got nil")
            )
        }

        let expectedRGB = extractRGBComponents(from: expectedColor)

        for color in colors {
            let actualRGB = extractRGBComponents(from: color)
            let distance = sqrt(
                pow(actualRGB.0 - expectedRGB.0, 2) +
                pow(actualRGB.1 - expectedRGB.1, 2) +
                pow(actualRGB.2 - expectedRGB.2, 2)
            )

            if distance < tolerance {
                return MatcherResult(
                    bool: true,
                    message: .expectedTo("contain color near \(expectedColor)")
                )
            }
        }

        return MatcherResult(
            bool: false,
            message: .expectedTo("contain color near \(expectedColor), but got \(colors)")
        )
    }
}
