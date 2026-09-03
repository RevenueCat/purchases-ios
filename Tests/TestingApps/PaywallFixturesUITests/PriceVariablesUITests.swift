//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceVariablesUITests.swift
//
//  Created by RevenueCat on 8/26/26.

import XCTest

/// Every currency and price variable, read off a rendered paywall rather than a unit-tested
/// function, so the value a customer sees is the value under assertion.
///
/// The fixture product is deliberately awkward: an annual USD product whose displayed price spells
/// the currency `USD`, the way the Ukraine storefront presents it, while the same product's
/// `NumberFormatter` spells it `US$`. Two pipelines render prices on a paywall and they disagree
/// here, so each row pins which one a given variable follows:
///
/// - `price` and `price_per_period` pass Apple's displayed string through, so they read `USD`
/// - `price_per_day/week/month/year` compute a `Decimal` and format it, so they read `US$`
/// - `currency_symbol` returns the currency's narrow symbol, so it reads `$`
///
/// `price` and `price_per_year` therefore render the same amount with different tokens. That is
/// current behavior, not an aspiration: if these three ever agree, this test should be rewritten
/// rather than deleted.
final class PriceVariablesUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The base price variables, on a product with no offer.
    func testBasePriceVariables() throws {
        let app = self.launch(fixture: "price_variables")

        self.assertRows(
            in: app,
            [
                "product.currency_code=USD",
                "product.currency_symbol=$",
                "product.price=79,99 USD",
                "product.price_per_period=79,99 USD/year",
                "product.price_per_period_abbreviated=79,99 USD/yr",
                "product.price_per_day=0,21\u{00A0}US$",
                "product.price_per_week=1,53\u{00A0}US$",
                "product.price_per_month=6,66\u{00A0}US$",
                "product.price_per_year=79,99\u{00A0}US$",
                "product.periodly=yearly"
            ]
        )
    }

    /// The offer variables, on the same product with a one-month pay-up-front introductory offer.
    /// `offer_price_per_year` is empty on purpose: a one-month offer has no yearly equivalent to
    /// show. `secondary_offer_price` is empty because the product carries no promotional offer.
    func testOfferPriceVariables() throws {
        let app = self.launch(fixture: "offer_price_variables")

        self.assertRows(
            in: app,
            [
                "product.currency_symbol=$",
                "product.offer_price=9,99 USD",
                "product.offer_price_per_day=0,33\u{00A0}US$",
                "product.offer_price_per_week=2,29\u{00A0}US$",
                "product.offer_price_per_month=9,99\u{00A0}US$",
                "product.offer_price_per_year=",
                "product.secondary_offer_price="
            ]
        )
    }

    /// `currency_symbol` must never render a currency code. That is the whole bug behind this
    /// fixture: Apple's displayed price says `USD`, and reading the token straight out of it put a
    /// three letter code where a paywall asked for a symbol.
    func testCurrencySymbolIsNeverACurrencyCode() throws {
        let app = self.launch(fixture: "price_variables")
        let rows = Self.rows(in: app)

        guard let symbol = rows.first(where: { $0.hasPrefix("product.currency_symbol=") }) else {
            return XCTFail("No currency_symbol row rendered. \(rows)")
        }

        let value = String(symbol.dropFirst("product.currency_symbol=".count))
        XCTAssertFalse(value.isEmpty, "currency_symbol rendered nothing.")
        XCTAssertNotEqual(value, "USD", "currency_symbol rendered the ISO code instead of a symbol.")
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
