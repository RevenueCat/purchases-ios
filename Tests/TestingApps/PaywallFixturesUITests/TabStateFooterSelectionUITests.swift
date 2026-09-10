//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabStateFooterSelectionUITests.swift
//
//  Created by Facundo Menzella on 9/10/26.

import XCTest

/// Tabs that hold no packages, with each tier's card in a sticky footer behind a "Selected tab"
/// rule on its wrapper stack. Cards rename themselves when selected, so the selection is readable
/// from the accessibility tree.
///
/// The tabs component publishes the selected tab into paywall state and only the wrapper stacks
/// read it, so nothing on a card says when it is shown. That is what selection used to miss.
final class TabStateFooterSelectionUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The paywall opens on the last tier, so the first frame is the one that used to show nothing
    /// selected while the purchase button held a card from another tier.
    func testDefaultTabSelectsItsOwnCardOnFirstFrame() throws {
        let app = self.launchFixture()

        XCTAssertTrue(
            app.buttons["Annual selected"].waitForExistence(timeout: 10),
            "The default tab's own card owns the selection. \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(app.buttons["Weekly selected"].exists)
        XCTAssertFalse(app.buttons["Monthly selected"].exists)
    }

    /// Switching tab swaps which wrapper stack is shown. The selection has to follow, or the
    /// paywall reads as having nothing chosen while Continue still holds the previous tier's card.
    func testSwitchingTabMovesSelectionToTheShowingTier() throws {
        let app = self.launchFixture()
        XCTAssertTrue(app.buttons["Annual selected"].waitForExistence(timeout: 10))

        app.buttons["Weekly tab"].tap()

        XCTAssertTrue(
            app.buttons["Weekly selected"].waitForExistence(timeout: 5),
            "The tier now showing owns the selection. \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(app.buttons["Annual selected"].exists)
    }

    /// And back again, so the fix is not "always pick the first tier".
    func testSwitchingTabAgainFollowsTheNewTier() throws {
        let app = self.launchFixture()
        XCTAssertTrue(app.buttons["Annual selected"].waitForExistence(timeout: 10))

        app.buttons["Weekly tab"].tap()
        XCTAssertTrue(app.buttons["Weekly selected"].waitForExistence(timeout: 5))

        app.buttons["Monthly tab"].tap()

        XCTAssertTrue(
            app.buttons["Monthly selected"].waitForExistence(timeout: 5),
            "The tier now showing owns the selection. \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(app.buttons["Weekly selected"].exists)
    }

    private func launchFixture() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "tab_state_footer_tiers"
        app.launch()
        return app
    }

    private static func visibleLabels(in app: XCUIApplication) -> String {
        return "Visible: " + app.buttons.allElementsBoundByIndex
            .map { $0.label }
            .joined(separator: ", ")
    }

}
