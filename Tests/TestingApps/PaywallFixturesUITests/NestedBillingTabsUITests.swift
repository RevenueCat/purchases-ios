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

final class NestedBillingTabsUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testBillingContentAndPurchaseSelectionFollowTheTierAcrossRepeatedSwitches() {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "nested_billing_tabs"
        app.launch()

        self.assertBilling("gold_annual", in: app)
        app.buttons["Gold Monthly"].firstMatch.tap()
        self.assertBilling("gold_monthly", in: app)

        for iteration in 0..<2 {
            app.buttons["Silver"].firstMatch.tap()
            self.assertBilling(iteration == 0 ? "silver_annual" : "silver_monthly", in: app)
            app.buttons["Silver Monthly"].firstMatch.tap()
            self.assertBilling("silver_monthly", in: app)

            app.buttons["Gold"].firstMatch.tap()
            self.assertBilling("gold_monthly", in: app)
        }
    }

    private func assertBilling(
        _ billingID: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", billingID)).firstMatch
        XCTAssertTrue(card.exists || card.waitForExistence(timeout: 5),
                      "Missing \(billingID) card", file: file, line: line)
        XCTAssertTrue(card.isHittable, file: file, line: line)

        let selected = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Selected '")).firstMatch
        let selectionMatches = NSPredicate { _, _ in
            guard selected.exists else { return false }
            let price = String(selected.label.dropFirst("Selected ".count))
            return !price.isEmpty && card.label.contains(price)
        }
        if selectionMatches.evaluate(with: nil) { return }
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: selectionMatches, object: nil)], timeout: 5),
            .completed,
            "Purchase selection must match the visible billing card",
            file: file,
            line: line
        )
    }

}
