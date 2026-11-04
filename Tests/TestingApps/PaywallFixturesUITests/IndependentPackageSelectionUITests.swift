//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IndependentPackageSelectionUITests.swift
//
//  Created by RevenueCat on 8/18/26.

import XCTest

final class IndependentPackageSelectionUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testEachTabUsesItsOwnIndependentDefaultAndPurchasePackage() {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "independent_tab_defaults"
        app.launch()

        self.assertSelectionAndPurchase("Monthly", packageID: "$rc_monthly", in: app)
        app.buttons["Annual default tab"].tap()
        self.assertSelectionAndPurchase("Annual", packageID: "$rc_annual", in: app)
        app.buttons["Monthly default tab"].tap()
        self.assertSelectionAndPurchase("Monthly", packageID: "$rc_monthly", in: app)
    }

    private func assertSelectionAndPurchase(_ label: String, packageID: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["\(label) selected"].waitForExistence(timeout: 10))
        app.buttons["Purchase"].tap()
        let result = app.alerts["Purchase callback"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.staticTexts[packageID].exists)
        result.buttons["OK"].tap()
    }

}
