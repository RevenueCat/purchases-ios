//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabSwitchSelectionUITests.swift
//
//  Created by Facundo Menzella on 9/17/26.

import XCTest

/// Each tier declares its own plans inside its tab, and the disclaimer sits outside them, so it
/// renders from the page context, which is the context the purchase button buys from.
///
/// The two tiers hold their cards at different depths, which is what makes this reproduce: the tab
/// subtree is replaced on a switch. Flattening them so both tiers match stops it reproducing, so
/// keep the shapes different when touching this fixture.
final class TabSwitchSelectionUITests: XCTestCase {

    private enum Tier {
        static let second = "Tier two"
        static let opening = "Tier three"
    }

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The reported wrong charge: pick the yearly plan in one tier, switch to another, and the
    /// disclaimer still names the plan left behind, which is also the one Continue buys.
    func testSwitchingTierAfterPickingAPlanMovesTheDisclaimer() throws {
        let app = self.launch()

        app.buttons[Tier.second].firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Subscribe Yearly"))
            .firstMatch.tap()

        app.buttons[Tier.opening].firstMatch.tap()
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Subscribe"))
                .firstMatch.waitForExistence(timeout: 5)
        )

        // Compared against what is on screen rather than a literal: both are formatted for the
        // runner's locale, so the amounts agree with each other but not with a hardcoded string.
        let shown = Self.amounts(in: Self.cardLabels(in: app).joined(separator: " "))
        let charged = Self.amounts(in: Self.disclaimer(in: app))

        XCTAssertFalse(charged.isEmpty, "No disclaimer price found. \(Self.visibleTexts(in: app))")
        XCTAssertTrue(
            charged.isSubset(of: shown),
            "The disclaimer names \(charged.sorted()), which is not on screen (\(shown.sorted())). "
                + "The plan left behind is still what gets bought. \(Self.visibleTexts(in: app))"
        )
    }

    /// Tapping the tier that is already selected republishes the same id. That must not be read
    /// as a switch, or restoring the tier default would discard the plan the user just picked.
    func testReTappingTheSelectedTierKeepsThePickedPlan() throws {
        let app = self.launch()

        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Subscribe Yearly"))
            .firstMatch.tap()
        let picked = Self.amounts(in: Self.disclaimer(in: app))
        XCTAssertFalse(picked.isEmpty, "No disclaimer price found. \(Self.visibleTexts(in: app))")

        app.buttons[Tier.opening].firstMatch.tap()

        XCTAssertEqual(
            Self.amounts(in: Self.disclaimer(in: app)), picked,
            "Re-tapping the selected tier changed the plan. \(Self.visibleTexts(in: app))"
        )
    }

    private static func amounts(in text: String) -> Set<String> {
        let pattern = try? NSRegularExpression(pattern: #"\d+[.,]\d\d"#)
        let range = NSRange(text.startIndex..., in: text)
        let matches = pattern?.matches(in: text, range: range) ?? []
        return Set(matches.compactMap { Range($0.range, in: text).map { String(text[$0]) } })
    }

    private static func cardLabels(in app: XCUIApplication) -> [String] {
        return app.buttons.allElementsBoundByIndex
            .map { $0.label }
            .filter { $0.contains("Subscribe") }
    }

    private static func disclaimer(in app: XCUIApplication) -> String {
        return app.staticTexts.allElementsBoundByIndex
            .map { $0.label }
            .first { $0.contains("refund") } ?? ""
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "reported_tabs"
        app.launch()
        XCTAssertTrue(
            app.buttons[Tier.second].firstMatch.waitForExistence(timeout: 15),
            "Fixture did not render. \(Self.visibleTexts(in: app))"
        )
        return app
    }

    private static func visibleTexts(in app: XCUIApplication) -> String {
        return "Visible: " + app.staticTexts.allElementsBoundByIndex
            .map { $0.label }
            .joined(separator: " | ")
    }

}
