//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageSelectionUITests.swift
//
//  Created by RevenueCat on 8/18/26.

import XCTest

/// Selection rules for a paywall with packages both outside and inside tabs, driven with real taps.
/// Each card renames itself when selected, so the selection is readable from the accessibility tree.
///
/// These cover what the user sees: the hidden default is never the selection, a tab owns the selection
/// while it is showing, and a tapped page card takes over without following the user into a tab that
/// does not offer it. Nothing else in the repo drives package selection with real taps.
///
/// They are area coverage rather than proof of one change: they pass with the page-scoped reconcile
/// and the reconcile marker both disabled, because tab propagation alone produces the same selection
/// in this fixture. Those two are pinned by `MixedTabsDefaultPackageVisibilityTests`, which can seed a
/// `PackageContext` directly and reach states a tap sequence cannot.
final class PackageSelectionUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The authored default is hidden, and the showing tab declares its own, so the tab's package
    /// owns the selection. Nothing may end up selected on the hidden card.
    func testHiddenDefaultIsNeverTheSelection() throws {
        let app = self.launchMixedTabs()

        XCTAssertTrue(
            app.buttons["Weekly selected"].waitForExistence(timeout: 10),
            "The showing tab's own package should be selected. \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(
            app.buttons["Annual selected"].exists,
            "The hidden authored default must never be the selection."
        )
    }

    /// Switching tabs hands the selection to the tab now showing.
    func testSwitchingTabsSelectsThatTabsOwnDefault() throws {
        let app = self.launchMixedTabs()
        XCTAssertTrue(app.buttons["Weekly selected"].waitForExistence(timeout: 10))

        app.buttons["Lifetime tab"].tap()

        XCTAssertTrue(
            app.buttons["Lifetime selected"].waitForExistence(timeout: 5),
            "Tab 2's own default should be selected. \(Self.visibleLabels(in: app))"
        )
    }

    /// A real tap on a page card takes the selection, and the tab it leaves behind must not keep
    /// claiming it.
    func testTappingAPageCardTakesTheSelection() throws {
        let app = self.launchMixedTabs()
        XCTAssertTrue(app.buttons["Weekly selected"].waitForExistence(timeout: 10))

        app.buttons["Monthly"].tap()

        XCTAssertTrue(
            app.buttons["Monthly selected"].waitForExistence(timeout: 5),
            "Tapping the page card should select it. \(Self.visibleLabels(in: app))"
        )
        XCTAssertFalse(app.buttons["Weekly selected"].exists)
    }

    /// After that tap, opening a tab still uses the tab's own default: the page package it replaces
    /// is not on offer there, so it cannot follow the user across.
    func testATappedPageCardDoesNotOutrankATabsOwnDefault() throws {
        let app = self.launchMixedTabs()
        XCTAssertTrue(app.buttons["Weekly selected"].waitForExistence(timeout: 10))

        app.buttons["Monthly"].tap()
        XCTAssertTrue(app.buttons["Monthly selected"].waitForExistence(timeout: 5))

        app.buttons["Lifetime tab"].tap()

        XCTAssertTrue(
            app.buttons["Lifetime selected"].waitForExistence(timeout: 5),
            "The tab's own default should win over the tapped page card. \(Self.visibleLabels(in: app))"
        )
    }

    private func launchMixedTabs() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "mixed_tabs_page_default"
        app.launch()
        return app
    }

    /// Included in failure messages so a broken fixture reports what did render. Package cards are
    /// buttons, not static text: the card is tappable, so its label carries the text.
    private static func visibleLabels(in app: XCUIApplication) -> String {
        return "Card labels: \(app.buttons.allElementsBoundByIndex.prefix(12).map(\.label))"
    }

}
