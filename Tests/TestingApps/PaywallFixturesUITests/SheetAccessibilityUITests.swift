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

    func testSheetDefaultOwnsPurchaseAndClosingRestoresRootSelection() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "competing_sheet_defaults"
        app.launch()
        XCTAssertTrue(app.buttons["Annual selected"].waitForExistence(timeout: 30), app.debugDescription)
        app.buttons["Monthly XL tab"].tap()
        XCTAssertTrue(app.buttons["Monthly XL selected"].waitForExistence(timeout: 5))
        app.buttons["Root monthly"].tap()
        XCTAssertTrue(app.buttons["Root monthly selected"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selected price: $4.99"].exists)

        app.buttons["Open plans"].tap()
        XCTAssertTrue(app.buttons["Annual XL selected"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Sheet price: $199.99"].exists)
        app.buttons["Purchase from sheet"].tap()
        let result = app.alerts["Purchase callback"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(result.staticTexts["annual_xl"].exists, result.debugDescription)
        result.buttons["OK"].tap()

        app.buttons["Close plans"].tap()
        XCTAssertTrue(app.buttons["Annual XL selected"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Root monthly selected"].exists)
        XCTAssertTrue(app.staticTexts["Selected price: $4.99"].exists)
        XCTAssertFalse(app.buttons["Monthly XL selected"].exists)
    }

    func testRootSelectionReplacesEarlierTabChoiceAfterRoundTrip() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "root_selection_tab_memory"
        app.launch()
        XCTAssertTrue(app.buttons["Annual"].waitForExistence(timeout: 30), app.debugDescription)

        app.buttons["Annual"].tap()
        XCTAssertTrue(app.buttons["Annual selected"].waitForExistence(timeout: 5))
        app.buttons["Root monthly"].tap()
        XCTAssertTrue(app.buttons["Tab monthly selected"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Root monthly selected"].exists)

        app.buttons["Monthly XL tab"].tap()
        XCTAssertTrue(app.buttons["Monthly XL selected"].waitForExistence(timeout: 5))
        app.buttons["Annual tab"].tap()
        XCTAssertTrue(app.buttons["Annual tab"].exists)

        app.buttons["Purchase root selection"].tap()
        let result = app.alerts["Purchase callback"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(result.staticTexts["$rc_monthly"].exists, result.debugDescription)
    }

}
