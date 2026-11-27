//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import XCTest

final class FillCarouselUITests: XCTestCase {

    func testFillPageUsesTheHeightAvailableToTheCarousel() {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "fill_carousel"
        app.launch()

        let title = app.staticTexts["Plan features"]
        let upgrade = app.staticTexts["Upgrade"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(upgrade.exists)
        let upgradeFrame = upgrade.frame
        XCTAssertEqual(upgradeFrame.maxY - title.frame.minY, 300, accuracy: 2)

        let lastFeature = app.staticTexts["Last feature"]
        let yBeforeScroll = lastFeature.frame.minY
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: upgradeFrame.midX, dy: upgradeFrame.minY - 20))
        let end = origin.withOffset(CGVector(dx: upgradeFrame.midX, dy: title.frame.maxY + 20))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertLessThan(lastFeature.frame.minY, yBeforeScroll)
        XCTAssertEqual(upgrade.frame.minY, upgradeFrame.minY, accuracy: 1)
    }

    func testFillCarouselInScrollingStackReservesSpaceForItsContent() {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "scrolling_fill_carousel"
        app.launch()

        let title = app.staticTexts["Plan features"]
        let upgrade = app.staticTexts["Upgrade"]
        let below = app.staticTexts["Below carousel"]
        XCTAssertTrue(below.waitForExistence(timeout: 5))
        XCTAssertTrue(title.exists)
        XCTAssertTrue(upgrade.exists)
        XCTAssertEqual(upgrade.frame.minY, title.frame.maxY, accuracy: 2)
        XCTAssertEqual(below.frame.minY, upgrade.frame.maxY, accuracy: 2)
    }

}
