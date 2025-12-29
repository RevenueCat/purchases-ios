//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScreenConditionTests.swift
//
//  Created by Jacob Zivan Rakidzich on 12/2/25.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ScreenConditionTests: TestCase {

    // MARK: - Initial State

    func testInitialStateIsUnknown() {
        let condition = ScreenCondition()

        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

    // MARK: - Orientation Detection

    func testOrientationIsPortraitWhenHeightGreaterThanWidth() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 375, height: 812)

        XCTAssertEqual(condition.orientation, .portrait)
    }

    func testOrientationIsLandscapeWhenWidthGreaterThanHeight() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 812, height: 375)

        XCTAssertEqual(condition.orientation, .landscape)
    }

    func testOrientationIsPortraitWhenWidthEqualsHeight() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 500, height: 500)

        XCTAssertEqual(condition.orientation, .portrait)
    }

    // MARK: - Invalid Size Handling

    func testOrientationIsUnknownWhenSizeIsNil() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = nil

        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

    func testOrientationIsUnknownWhenWidthIsZero() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 0, height: 812)

        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

    func testOrientationIsUnknownWhenHeightIsZero() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 375, height: 0)

        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

    func testOrientationIsUnknownWhenBothDimensionsAreZero() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 0, height: 0)

        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

    // MARK: - Screen Size Breakpoint Selection (Portrait)

    func testScreenSizeIsMobileForSmallPortraitSize() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 375, height: 812)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    func testScreenSizeIsMobileAtExactMobileBreakpoint() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 375, height: 667)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    func testScreenSizeIsTabletForMediumPortraitSize() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 768, height: 1024)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.tablet)
    }

    func testScreenSizeIsTabletAtExactTabletBreakpoint() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 700, height: 900)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.tablet)
    }

    func testScreenSizeIsDesktopForLargePortraitSize() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 1024, height: 1366)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.desktop)
    }

    // MARK: - Effective Width Uses Shortest Dimension

    func testEffectiveWidthUsesShortestDimensionInLandscape() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // Landscape: width=812, height=375 -> effectiveWidth = min(812, 375) = 375
        condition.paywallSize = CGSize(width: 812, height: 375)

        XCTAssertEqual(condition.orientation, .landscape)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    func testEffectiveWidthUsesShortestDimensionInPortrait() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // Portrait: width=375, height=812 -> effectiveWidth = min(375, 812) = 375
        condition.paywallSize = CGSize(width: 375, height: 812)

        XCTAssertEqual(condition.orientation, .portrait)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    func testLandscapeTabletUsesHeightAsEffectiveWidth() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // Landscape: width=1024, height=768 -> effectiveWidth = min(1024, 768) = 768
        condition.paywallSize = CGSize(width: 1024, height: 768)

        XCTAssertEqual(condition.orientation, .landscape)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.tablet)
    }

    // MARK: - Breakpoint Edge Cases

    func testScreenSizeIsMobileJustBelowTabletBreakpoint() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // effectiveWidth = 699, just below tablet (700)
        condition.paywallSize = CGSize(width: 699, height: 900)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    func testScreenSizeIsTabletJustBelowDesktopBreakpoint() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // effectiveWidth = 1023, just below desktop (1024)
        condition.paywallSize = CGSize(width: 1023, height: 1400)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.tablet)
    }

    func testScreenSizeIsDesktopAtExactDesktopBreakpoint() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        condition.paywallSize = CGSize(width: 1024, height: 1400)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.desktop)
    }

    // MARK: - Custom Screen Sizes

    func testCustomScreenSizesAreUsed() {
        let customSizes = [
            UIConfig.ScreenSize(name: "small", width: 320),
            UIConfig.ScreenSize(name: "large", width: 600)
        ]
        let condition = ScreenCondition(screenSizes: customSizes)
        condition.paywallSize = CGSize(width: 500, height: 800)

        XCTAssertEqual(condition.screenSize?.name, "small")
    }

    func testCustomScreenSizesLargeBreakpoint() {
        let customSizes = [
            UIConfig.ScreenSize(name: "small", width: 320),
            UIConfig.ScreenSize(name: "large", width: 600)
        ]
        let condition = ScreenCondition(screenSizes: customSizes)
        condition.paywallSize = CGSize(width: 600, height: 800)

        XCTAssertEqual(condition.screenSize?.name, "large")
    }

    // MARK: - Empty Screen Sizes Falls Back to Defaults

    func testEmptyScreenSizesFallsBackToDefaults() {
        let condition = ScreenCondition(screenSizes: [])
        condition.paywallSize = CGSize(width: 375, height: 812)

        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    // MARK: - Size Below All Breakpoints

    func testSizeBelowAllBreakpointsReturnsFirstScreenSize() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
        // effectiveWidth = 100, below mobile (375)
        condition.paywallSize = CGSize(width: 100, height: 200)

        // Falls back to first screenSize when no breakpoint matches
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)
    }

    // MARK: - State Updates on Size Change

    func testStateUpdatesWhenSizeChanges() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)

        // Start with mobile portrait
        condition.paywallSize = CGSize(width: 375, height: 812)
        XCTAssertEqual(condition.orientation, .portrait)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.mobile)

        // Change to tablet landscape
        condition.paywallSize = CGSize(width: 1024, height: 768)
        XCTAssertEqual(condition.orientation, .landscape)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.tablet)

        // Change to desktop portrait
        condition.paywallSize = CGSize(width: 1024, height: 1366)
        XCTAssertEqual(condition.orientation, .portrait)
        XCTAssertEqual(condition.screenSize, UIConfig.ScreenSize.Defaults.desktop)
    }

    func testStateResetsToUnknownWhenSizeBecomesInvalid() {
        let condition = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)

        // Start with valid size
        condition.paywallSize = CGSize(width: 375, height: 812)
        XCTAssertEqual(condition.orientation, .portrait)
        XCTAssertNotNil(condition.screenSize)

        // Set to nil
        condition.paywallSize = nil
        XCTAssertEqual(condition.orientation, .unknown)
        XCTAssertNil(condition.screenSize)
    }

}

#endif
