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

final class VideoCloseUITests: XCTestCase {

    func testCloseButtonAboveVideoReceivesTap() {
        self.continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "video_close"
        app.launch()

        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: close.frame.maxY + 100)).tap()
        XCTAssertTrue(app.buttons["Play/Pause"].waitForExistence(timeout: 10), app.debugDescription)
        close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 5))
    }

    func testCircleVideoIgnoresTapsOutsideItsShape() {
        self.continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "video_close"
        app.launchEnvironment["VIDEO_CIRCLE_SHAPE"] = "1"
        app.launch()

        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        let center = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: close.frame.maxY + 100))
        let playbackControl = app.buttons["Play/Pause"]
        center.tap()
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 10), app.debugDescription)
        let videoTop = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: app.frame.midX, dy: close.frame.maxY + 40))
        videoTop.tap()
        XCTAssertTrue(playbackControl.waitForNonExistence(timeout: 10), app.debugDescription)

        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: close.frame.minX + 20, dy: close.frame.maxY + 20)).tap()
        XCTAssertFalse(playbackControl.waitForExistence(timeout: 2), app.debugDescription)

        videoTop.tap()
        XCTAssertTrue(playbackControl.waitForExistence(timeout: 5), app.debugDescription)
    }

}
