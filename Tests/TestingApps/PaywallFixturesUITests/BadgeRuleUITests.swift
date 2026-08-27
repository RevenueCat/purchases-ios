//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BadgeRuleUITests.swift
//

import XCTest

final class BadgeRuleUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The row has one badge rule per offer type, and rules are last-match-wins. A customer
    /// matching both gets the promo rule's badge, so the promo badge's own copy has to render.
    /// Showing "Badge" means the badge came from one rule and its copy from another, which leaves
    /// the placeholder nobody fills in because it is never meant to be seen.
    func testBadgeShowsTheCopyOfTheRuleThatSuppliedIt() throws {
        let app = self.launch(fixture: "badge_rules_per_offer")

        XCTAssertTrue(
            app.staticTexts["PROMO BADGE"].waitForExistence(timeout: 10),
            "Badge did not render the promo rule's copy. On screen: \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(
            app.staticTexts["Badge"].exists,
            "Badge rendered its placeholder copy. On screen: \(Self.visibleLabels(in: app))"
        )
    }

    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = fixture
        app.launch()
        return app
    }

    private static func visibleLabels(in app: XCUIApplication) -> String {
        let texts = app.staticTexts.allElementsBoundByIndex.prefix(12).map(\.label)
        return texts.joined(separator: ", ")
    }

}
