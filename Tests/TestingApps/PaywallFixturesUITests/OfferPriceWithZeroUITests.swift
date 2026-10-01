//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferPriceWithZeroUITests.swift
//

import XCTest

/// Every offer price variable next to its `_with_zero` twin, read off a rendered paywall.
///
/// The fixture product carries a one month free trial on an annual subscription. On a free trial
/// the plain variables substitute the localized word, the `_with_zero` ones format the amount.
/// A paywall author writing "Try for {{ ... }} now" wants the second column.
final class OfferPriceWithZeroUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testFreeTrialRendersTheWordAndTheAmountSideBySide() throws {
        let app = self.launch(fixture: "offer_price_with_zero")

        self.assertRows(
            in: app,
            [
                // The offer is monthly, so the per-year rows are empty on both sides: a one month
                // trial has no yearly equivalent to show.
                "product.offer_price=Free",
                "product.offer_price_with_zero=$0.00",
                "product.offer_price_per_day=Free",
                "product.offer_price_with_zero_per_day=$0.00",
                "product.offer_price_per_week=Free",
                "product.offer_price_with_zero_per_week=$0.00",
                "product.offer_price_per_month=Free",
                "product.offer_price_with_zero_per_month=$0.00",
                "product.offer_price_per_year=",
                "product.offer_price_with_zero_per_year="
            ]
        )
    }

    /// The whole point of the variable: no `_with_zero` row may render a word.
    func testNoWithZeroRowRendersAWord() throws {
        let app = self.launch(fixture: "offer_price_with_zero")
        let rows = Self.rows(in: app)

        let withZero = rows.filter { $0.hasPrefix("product.offer_price_with_zero") }
        XCTAssertFalse(withZero.isEmpty, "No _with_zero rows rendered. \(rows)")

        for row in withZero {
            let value = String(row.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).last ?? "")
            // An empty row is the period guard, not a word. Only rendered values are asserted.
            guard !value.isEmpty else { continue }
            XCTAssertTrue(
                value.contains(where: \.isNumber),
                "\(row) rendered a word instead of an amount."
            )
        }
    }

    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = fixture
        app.launch()
        XCTAssertTrue(
            app.staticTexts.element(boundBy: 0).waitForExistence(timeout: 10),
            "The fixture paywall never rendered any text."
        )
        return app
    }

    /// Asserts row by row so a failure names the variable that moved rather than diffing one blob.
    private func assertRows(in app: XCUIApplication, _ expected: [String]) {
        let rendered = Self.rows(in: app)

        for expectedRow in expected {
            let name = expectedRow.prefix { $0 != "=" }
            guard let actual = rendered.first(where: { $0.hasPrefix("\(name)=") }) else {
                XCTFail("\(name) did not render. Rendered rows: \(rendered)")
                continue
            }
            XCTAssertEqual(actual, expectedRow)
        }

        XCTAssertEqual(
            rendered.count,
            expected.count,
            "The fixture rendered a different number of variables than asserted. \(rendered)"
        )
    }

    /// Variable rows are the only labels carrying `=`, and an empty value still renders the name.
    private static func rows(in app: XCUIApplication) -> [String] {
        return app.staticTexts.allElementsBoundByIndex.map(\.label).filter { $0.contains("=") }
    }

}
