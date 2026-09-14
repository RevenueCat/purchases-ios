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

/// Whether the paywall behind a sheet leaves the accessibility tree cannot be asserted here:
/// XCUITest lists elements that carry `accessibilityHidden`, and reports them as accessibility
/// elements, which `PaywallAccessibilityUITests.testElementQueriesListEvenHiddenImages` pins down.
/// `performAccessibilityAudit` has no check for reachability behind a modal either.
///
/// So this only holds the fixture open for a VoiceOver pass on device: open the sheet, then swipe
/// through. Focus should stay inside the sheet and never reach "Text behind the sheet".
final class SheetAccessibilityUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The fixture itself still has to work, or the manual pass has nothing to look at.
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
