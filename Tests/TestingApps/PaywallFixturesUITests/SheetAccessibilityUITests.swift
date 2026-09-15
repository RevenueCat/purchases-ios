//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SheetAccessibilityUITests.swift

import XCTest

/// XCUITest reports elements carrying `accessibilityHidden` as present and as accessibility
/// elements (see `testElementQueriesListEvenHiddenImages`), so what this PR changes can only be
/// checked with VoiceOver on device. This keeps the fixture working for that pass.
final class SheetAccessibilityUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testTheSheetOpensOverTheContent() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "sheet_over_content"
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Text behind the sheet"].waitForExistence(timeout: 30),
            app.debugDescription
        )

        app.buttons["Open the sheet"].tap()

        XCTAssertTrue(
            app.staticTexts["Text inside the sheet"].waitForExistence(timeout: 10),
            app.debugDescription
        )
    }

}
