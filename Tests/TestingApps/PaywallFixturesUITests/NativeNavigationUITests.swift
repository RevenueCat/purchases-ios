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

final class NativeNavigationUITests: XCTestCase {
    private let backIdentifier = "RevenueCat.NativePaywallBack"
    private let closeIdentifier = "RevenueCat.NativePaywallClose"

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testNativeBackNavigatesWithinWorkflowWithoutPoppingCallerNavigation() {
        let app = self.launch("native_workflow_navigation")
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        app.buttons["Continue"].tap()

        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        let back = app.buttons[self.backIdentifier]
        XCTAssertTrue(back.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(back.isHittable, app.debugDescription)
        XCTAssertTrue(app.buttons[self.closeIdentifier].isHittable, app.debugDescription)
        XCTAssertFalse(app.buttons["Designed Back"].exists, app.debugDescription)
        XCTAssertFalse(app.buttons["Designed Close"].exists, app.debugDescription)
        // This pushed paywall replaces the caller's automatic Back while the workflow has history.
        XCTAssertEqual(Set(app.buttons.allElementsBoundByIndex.filter { $0.isHittable }.map { $0.identifier }),
                       Set([self.backIdentifier, self.closeIdentifier]), app.debugDescription)
        back.tap()

        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        XCTAssertFalse(app.buttons[self.backIdentifier].exists, app.debugDescription)
        XCTAssertFalse(app.buttons["Show native paywall"].exists, app.debugDescription)
        app.buttons[self.closeIdentifier].tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 10), app.debugDescription)
    }

    func testInlineSheetKeepsItsDesignedCloseAndRestoresOuterNativeClose() {
        let app = self.launch("native_inline_sheet")
        let outerClose = app.buttons[self.closeIdentifier]
        XCTAssertTrue(outerClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(outerClose.isHittable, app.debugDescription)
        app.buttons["Open inline sheet"].tap()

        let sheetClose = app.buttons["Designed sheet Close"]
        XCTAssertTrue(sheetClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(sheetClose.isHittable, app.debugDescription)
        XCTAssertFalse(outerClose.exists, app.debugDescription)
        XCTAssertFalse(app.buttons[self.backIdentifier].exists, app.debugDescription)
        sheetClose.tap()

        XCTAssertTrue(outerClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(outerClose.isHittable, app.debugDescription)
        XCTAssertTrue(app.staticTexts["Outer paywall"].exists, app.debugDescription)
        XCTAssertFalse(sheetClose.exists, app.debugDescription)
        XCTAssertFalse(app.staticTexts["Paywall dismissed"].exists, app.debugDescription)
        outerClose.tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 10), app.debugDescription)
    }

    private func launch(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = fixture
        app.launch()
        let showPaywall = app.buttons["Show native paywall"]
        XCTAssertTrue(showPaywall.waitForExistence(timeout: 30), app.debugDescription)
        showPaywall.tap()
        return app
    }

    private func assertVisible(_ element: XCUIElement, in app: XCUIApplication) {
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"),
                                               object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 10), .completed, app.debugDescription)
    }
}
