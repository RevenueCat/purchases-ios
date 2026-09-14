//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabStaleFooterPriceUITests.swift
//
//  Created by Facundo Menzella on 9/14/26.

import XCTest

/// The price sits outside the tabs, so it renders from the page-level context, which is also the
/// context the purchase button buys from. Switching to a tab that has nothing to select must not
/// leave that price, and therefore the purchase, on the tab that was left behind.
final class TabStaleFooterPriceUITests: XCTestCase {

    private enum Price {
        static let monthly = "Footer $4.99"
        static let annual = "Footer $39.99"
    }

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testPriceFollowsTheSelectionWithinATab() throws {
        let app = self.launch()

        XCTAssertTrue(
            app.staticTexts[Price.monthly].waitForExistence(timeout: 10),
            "The tab's default owns the price. \(Self.visibleTexts(in: app))"
        )

        app.buttons["Annual"].tap()

        XCTAssertTrue(
            app.staticTexts[Price.annual].waitForExistence(timeout: 5),
            "Selecting a card moves the price. \(Self.visibleTexts(in: app))"
        )
    }

    /// The reported bug: after switching, the price kept naming the package from the previous tab,
    /// and Continue bought it.
    func testSwitchingToATabWithNothingToSelectDropsThePreviousTabsPrice() throws {
        let app = self.launch()
        XCTAssertTrue(app.staticTexts[Price.monthly].waitForExistence(timeout: 10))

        app.buttons["Annual"].tap()
        XCTAssertTrue(app.staticTexts[Price.annual].waitForExistence(timeout: 5))

        app.buttons["Tab B"].tap()

        let stalePrice = app.staticTexts[Price.annual]
        let disappeared = stalePrice.waitForNonExistence(timeout: 5)

        XCTAssertTrue(
            disappeared,
            "Tab B offers nothing to select, so the price must not still name Tab A's package. "
                + "\(Self.visibleTexts(in: app))"
        )
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "tab_stale_footer_price"
        app.launch()
        return app
    }

    private static func visibleTexts(in app: XCUIApplication) -> String {
        return "Visible: " + app.staticTexts.allElementsBoundByIndex
            .map { $0.label }
            .joined(separator: " | ")
    }

}
