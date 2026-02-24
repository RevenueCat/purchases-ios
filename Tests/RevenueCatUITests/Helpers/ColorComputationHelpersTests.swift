//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ColorComputationHelpersTests.swift
//
//  Created by Facundo Menzella on 2/24/26.

import Nimble
@testable import RevenueCatUI
import SwiftUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ColorComputationHelpersTests: TestCase {

    #if os(watchOS)
    let toleranceRGBExtraction = 0.05
    #else
    let toleranceRGBExtraction = 0.01
    #endif

    // MARK: - linearize tests

    func testLinearizeZeroReturnsZero() {
        expect(linearize(0.0)).to(beCloseTo(0.0, within: 0.0001))
    }

    func testLinearizeOneReturnsOne() {
        expect(linearize(1.0)).to(beCloseTo(1.0, within: 0.0001))
    }

    func testLinearizeBelowThresholdUsesLinearFormula() {
        // Below threshold (0.04045), should use value / 12.92
        let value = 0.04
        let expected = value / 12.92
        expect(linearize(value)).to(beCloseTo(expected, within: 0.0001))
    }

    func testLinearizeAboveThresholdUsesGammaFormula() {
        // Above threshold, should use ((value + 0.055) / 1.055) ^ 2.4
        let value = 0.5
        let expected = pow((value + 0.055) / 1.055, 2.4)
        expect(linearize(value)).to(beCloseTo(expected, within: 0.0001))
    }

    func testLinearizeAtThreshold() {
        // At threshold, both formulas should give similar results
        let threshold = 0.04045
        let linearResult = threshold / 12.92
        let gammaResult = pow((threshold + 0.055) / 1.055, 2.4)
        // The formulas are designed to be continuous at this point
        expect(linearResult).to(beCloseTo(gammaResult, within: 0.001))
    }

    // MARK: - extractRGBComponents tests

    func testExtractRGBComponentsFromWhite() {
        let rgb = extractRGBComponents(from: .white)
        expect(rgb.0).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(1.0, within: toleranceRGBExtraction))
    }

    func testExtractRGBComponentsFromBlack() {
        let rgb = extractRGBComponents(from: .black)
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    func testExtractRGBComponentsFromPureRed() {
        // Use explicit RGB color since SwiftUI .red is a system color
        let pureRed = Color(red: 1.0, green: 0.0, blue: 0.0)
        let rgb = extractRGBComponents(from: pureRed)
        expect(rgb.0).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    func testExtractRGBComponentsFromPureGreen() {
        let pureGreen = Color(red: 0.0, green: 1.0, blue: 0.0)
        let rgb = extractRGBComponents(from: pureGreen)
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    func testExtractRGBComponentsFromPureBlue() {
        let pureBlue = Color(red: 0.0, green: 0.0, blue: 1.0)
        let rgb = extractRGBComponents(from: pureBlue)
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(1.0, within: toleranceRGBExtraction))
    }

    func testExtractRGBComponentsFromCustomColor() {
        // Create a custom color with known RGB values
        let color = Color(red: 0.5, green: 0.25, blue: 0.75)
        let rgb = extractRGBComponents(from: color)
        expect(rgb.0).to(beCloseTo(0.5, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.25, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.75, within: toleranceRGBExtraction))
    }

    // MARK: - selectColorWithBestContrast tests

    func testSelectColorWithBestContrastEmptyArrayReturnsBlack() {
        let result = selectColorWithBestContrast(from: [], againstColor: .white)
        let rgb = extractRGBComponents(from: result)
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    func testSelectColorWithBestContrastWhiteVsBlackOnWhiteBackground() {
        // Black should have better contrast against white background
        let colors: [Color] = [.white, .black]
        let result = selectColorWithBestContrast(from: colors, againstColor: .white)
        let rgb = extractRGBComponents(from: result)
        // Should select black
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    func testSelectColorWithBestContrastWhiteVsBlackOnBlackBackground() {
        // White should have better contrast against black background
        let colors: [Color] = [.white, .black]
        let result = selectColorWithBestContrast(from: colors, againstColor: .black)
        let rgb = extractRGBComponents(from: result)
        // Should select white
        expect(rgb.0).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(1.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(1.0, within: toleranceRGBExtraction))
    }

    func testSelectColorWithBestContrastSingleColorReturnsIt() {
        let colors: [Color] = [.red]
        let result = selectColorWithBestContrast(from: colors, againstColor: .white)
        let rgb = extractRGBComponents(from: result)
        expect(rgb.0).to(beCloseTo(1.0, within: toleranceRGBExtraction))
    }

    func testSelectColorWithBestContrastOnGrayBackground() {
        // On a mid-gray background, both black and white should have similar contrast
        // but one will be slightly better depending on the exact gray
        let gray = Color(red: 0.5, green: 0.5, blue: 0.5)
        let colors: [Color] = [.white, .black]
        let result = selectColorWithBestContrast(from: colors, againstColor: gray)

        // Either black or white is acceptable - just verify we get one of them
        let rgb = extractRGBComponents(from: result)
        let isBlackOrWhite = (rgb.0 < 0.1 && rgb.1 < 0.1 && rgb.2 < 0.1) ||
                             (rgb.0 > 0.9 && rgb.1 > 0.9 && rgb.2 > 0.9)
        expect(isBlackOrWhite).to(beTrue())
    }

    func testSelectColorWithBestContrastMultipleColors() {
        // Given dark background, lighter colors should win
        let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
        let colors: [Color] = [
            Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray - low contrast
            Color(red: 0.9, green: 0.9, blue: 0.9), // Light gray - high contrast
            Color(red: 0.5, green: 0.5, blue: 0.5)  // Mid gray - medium contrast
        ]
        let result = selectColorWithBestContrast(from: colors, againstColor: darkBackground)
        let rgb = extractRGBComponents(from: result)
        // Should select the light gray (0.9, 0.9, 0.9)
        expect(rgb.0).to(beCloseTo(0.9, within: 0.05))
        expect(rgb.1).to(beCloseTo(0.9, within: 0.05))
        expect(rgb.2).to(beCloseTo(0.9, within: 0.05))
    }

    // MARK: - WCAG Contrast Ratio Verification

    func testWCAGContrastRatioBlackOnWhiteIs21To1() {
        // The maximum contrast ratio per WCAG is 21:1 (black on white or vice versa)
        // We can verify this indirectly by checking that black is always selected over
        // any other color when contrasting against white
        let colors: [Color] = [
            .black,
            Color(red: 0.1, green: 0.1, blue: 0.1),
            Color(red: 0.2, green: 0.2, blue: 0.2)
        ]
        let result = selectColorWithBestContrast(from: colors, againstColor: .white)
        let rgb = extractRGBComponents(from: result)
        // Should select pure black
        expect(rgb.0).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.1).to(beCloseTo(0.0, within: toleranceRGBExtraction))
        expect(rgb.2).to(beCloseTo(0.0, within: toleranceRGBExtraction))
    }

    // MARK: - WCAGConstants validation

    func testWCAGConstantsLuminanceCoefficientsSum() {
        // The luminance coefficients should sum to 1.0
        let sum = WCAGConstants.redLuminanceCoefficient +
                  WCAGConstants.greenLuminanceCoefficient +
                  WCAGConstants.blueLuminanceCoefficient
        expect(sum).to(beCloseTo(1.0, within: 0.0001))
    }

    func testWCAGConstantsGreenCoefficientIsLargest() {
        // Human eyes are most sensitive to green
        expect(WCAGConstants.greenLuminanceCoefficient)
            .to(beGreaterThan(WCAGConstants.redLuminanceCoefficient))
        expect(WCAGConstants.greenLuminanceCoefficient)
            .to(beGreaterThan(WCAGConstants.blueLuminanceCoefficient))
    }

    func testWCAGConstantsBlueCoefficientIsSmallest() {
        // Human eyes are least sensitive to blue
        expect(WCAGConstants.blueLuminanceCoefficient)
            .to(beLessThan(WCAGConstants.redLuminanceCoefficient))
        expect(WCAGConstants.blueLuminanceCoefficient)
            .to(beLessThan(WCAGConstants.greenLuminanceCoefficient))
    }

}
