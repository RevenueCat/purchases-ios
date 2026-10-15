//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaymentSheetLockUITests.swift

import XCTest

/// The device locking while the App Store payment sheet is up (#7864). The sheet's keyboard is not
/// the paywall's, so the paywall must not move for it, and must come back laid out as before after
/// the sheet is dismissed in the background.
final class PaymentSheetLockUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testPaywallKeepsItsLayoutAfterTheSheetIsDismissedInTheBackground() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "reported_tabs"
        app.launchEnvironment["PAYWALL_PAYMENT_SHEET"] = "dismissed_by_lock"
        app.launch()

        // The purchase button relabels itself while purchasing, so the footer's link is the probe.
        let purchaseButton = app.buttons["Continue"]
        let footerLink = app.buttons["Terms of Use"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 10))
        let frameBefore = footerLink.frame

        purchaseButton.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "The sheet's keyboard should show.")
        XCTAssertEqual(footerLink.frame, frameBefore, "The paywall should not move for the sheet's keyboard.")

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let sheetField = app.secureTextFields["payment_sheet_password"]
        XCTAssertTrue(sheetField.waitForNonExistence(timeout: 5), "The sheet should be gone after the lock.")
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 5), "The cancel should restore the button.")

        XCTAssertEqual(
            footerLink.frame,
            frameBefore,
            "The paywall should be laid out as it was before the payment sheet."
        )
    }

}
