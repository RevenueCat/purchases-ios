// Created by Monika on 2026-10-14.

import XCTest

/// Real button taps through the SPI preview, both with and without a configured Purchases singleton.
final class CustomerCenterPreviewUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLegacyTermsAndPrivacyAreIntercepted() {
        for configured in [false, true] {
            let app = launch(mode: "legacy", configured: configured)
            openPreview(app)
            XCTAssertTrue(app.staticTexts["Legacy preview"].waitForExistence(timeout: 10), app.debugDescription)
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Terms")).firstMatch.tap()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Privacy")).firstMatch.tap()
            XCTAssertEqual(app.webViews.count, 0)
            app.buttons["Close"].firstMatch.tap()
            assertEvent("https://example.invalid/terms", in: app)
            assertEvent("https://example.invalid/privacy", in: app)
        }
    }

    func testWebCheckoutDismissesWhenConfigured() {
        verifyCheckout(mode: "checkout_dismiss", dismisses: true)
    }

    func testWebCheckoutRemainsOpenWhenConfigured() {
        verifyCheckout(mode: "checkout_stay", dismisses: false)
    }

    func testWebLinkDismissesAndIsIntercepted() {
        verifyCheckout(mode: "web_link", dismisses: true)
    }

    func testContactSupportIsIntercepted() {
        for configured in [false, true] {
            let app = launch(mode: "legacy", configured: configured)
            let button = app.descendants(matching: .any).matching(identifier: "Contact support").firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10), app.debugDescription)
            button.tap()
            assertEvent("mailto:support@example.invalid", in: app)
            XCTAssertEqual(app.webViews.count, 0)
        }
    }

    func testCheckoutWaitsForProviderBeforeDismissal() {
        for mode in ["checkout_dismiss", "web_link"] {
            for configured in [false, true] {
                let app = launch(mode: mode, configured: configured, outcome: "delayed")
                openPreview(app)
                let checkout = app.buttons["Preview checkout"]
                XCTAssertTrue(checkout.waitForExistence(timeout: 10))
                checkout.tap()
                // The checkout label becomes a spinner while pending; the close button identifies the sheet.
                let close = app.buttons["Close preview"]
                XCTAssertTrue(close.exists, "Paywall dismissed while the provider was still working")
                XCTAssertTrue(close.waitForNonExistence(timeout: 10))
                assertEvent("https://example.invalid/checkout", in: app)
            }
        }
    }

    func testFailedCheckoutKeepsPaywallOpen() {
        for mode in ["checkout_dismiss", "web_link"] {
            for configured in [false, true] {
                let app = launch(mode: mode, configured: configured, outcome: "failure")
                openPreview(app)
                let checkout = app.buttons["Preview checkout"]
                XCTAssertTrue(checkout.waitForExistence(timeout: 10))
                checkout.tap()
                XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
                XCTAssertTrue(app.alerts.staticTexts["Preview checkout failed"].exists)
                app.alerts.buttons.firstMatch.tap()
                XCTAssertTrue(checkout.isHittable)
                XCTAssertEqual(app.webViews.count, 0)
                app.buttons["Close preview"].tap()
            }
        }
    }

    func testHostedCheckoutUsesSimulatedPurchaseOutcomes() {
        for outcome in ["success", "cancel", "failure"] {
            for configured in [false, true] {
                let app = launch(mode: "hosted", configured: configured, outcome: outcome)
                openPreview(app)
                let checkout = app.buttons["Preview checkout"]
                XCTAssertTrue(checkout.waitForExistence(timeout: 10))
                checkout.tap()
                if outcome == "failure" {
                    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
                    XCTAssertTrue(app.alerts.staticTexts["Preview purchase failed"].exists)
                    app.alerts.buttons.firstMatch.tap()
                } else {
                    XCTAssertEqual(app.alerts.count, 0)
                }
                XCTAssertEqual(app.webViews.count, 0)
                if app.buttons["Close preview"].exists { app.buttons["Close preview"].tap() }
                assertEvent("purchase", in: app)
            }
        }
    }

    func testPreviewHelpActionsDisableCompetingButtonsAndAvoidSync() {
        for configured in [false, true] {
            let app = launch(mode: "actions", configured: configured, outcome: "delayed")
            let cancel = app.descendants(matching: .any).matching(identifier: "Preview cancel").firstMatch
            let plans = app.descendants(matching: .any).matching(identifier: "Preview change plan").firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 10), app.debugDescription)
            cancel.tap()
            assertEvent("started manage", in: app)
            XCTAssertFalse(cancel.isEnabled)
            XCTAssertFalse(plans.isEnabled)
            assertEvent("completed manage", in: app)
            XCTAssertTrue(plans.wait(for: \.isEnabled, toEqual: true, timeout: 5))
            plans.tap()
            assertEvent("completed change", in: app)
            XCTAssertFalse(app.staticTexts["preview.events"].label.contains("sync"))
            XCTAssertEqual(app.webViews.count, 0)
        }
    }

    func testPreviewHelpActionFailureIsVisibleAndAllowsRetry() {
        for configured in [false, true] {
            let app = launch(mode: "actions", configured: configured, outcome: "failure")
            let cancel = app.descendants(matching: .any).matching(identifier: "Preview cancel").firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 10), app.debugDescription)
            cancel.tap()
            let alert = app.alerts["Preview action failed"]
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
            XCTAssertTrue(alert.staticTexts["Preview action could not finish"].exists)
            alert.buttons["OK"].tap()
            XCTAssertTrue(cancel.isEnabled)
            app.descendants(matching: .any).matching(identifier: "Preview change plan").firstMatch.tap()
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
            assertEvent("started change", in: app)
        }
    }

    func testLeavingPreviewCancelsActionWithoutReplay() {
        for configured in [false, true] {
            let app = launch(mode: "actions", configured: configured, outcome: "delayed")
            let cancel = app.descendants(matching: .any).matching(identifier: "Preview cancel").firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 10), app.debugDescription)
            cancel.tap()
            app.buttons["Hide customer center"].tap()
            assertEvent("cancelled manage", in: app)
            app.buttons["Show customer center"].tap()
            XCTAssertTrue(cancel.waitForExistence(timeout: 10))
            XCTAssertTrue(cancel.isEnabled)
            let events = app.staticTexts["preview.events"].label
            XCTAssertEqual(events.components(separatedBy: "started manage").count - 1, 1)
            XCTAssertFalse(events.contains("completed manage"))
            XCTAssertEqual(app.alerts.count, 0)
        }
    }

    private func verifyCheckout(mode: String, dismisses: Bool) {
        for configured in [false, true] {
            let app = launch(mode: mode, configured: configured)
            openPreview(app)
            let checkout = app.buttons["Preview checkout"]
            XCTAssertTrue(checkout.waitForExistence(timeout: 10), app.debugDescription)
            checkout.tap()
            if dismisses {
                XCTAssertTrue(checkout.waitForNonExistence(timeout: 5), app.debugDescription)
            } else {
                // A second tap verifies that the first leaves the actual paywall interactive.
                XCTAssertTrue(checkout.isHittable)
                checkout.tap()
                app.buttons["Close preview"].tap()
            }
            XCTAssertEqual(app.webViews.count, 0)
            assertEvent("https://example.invalid/checkout", in: app)
            if mode != "web_link" {
                assertEvent("user=preview%20customer", in: app)
                assertEvent("env=sandbox", in: app)
            }
        }
    }

    private func launch(mode: String, configured: Bool, outcome: String = "success") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "customer_center_preview"
        app.launchEnvironment["PREVIEW_PAYWALL"] = mode
        app.launchEnvironment["PREVIEW_ACTION_OUTCOME"] = outcome
        app.launchEnvironment["PREVIEW_CONFIGURE_SDK"] = configured ? "1" : "0"
        app.launch()
        XCTAssertTrue(app.staticTexts[configured ? "SDK configured" : "SDK unconfigured"].waitForExistence(timeout: 15))
        return app
    }

    private func openPreview(_ app: XCUIApplication) {
        let button = app.buttons["Open preview"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), app.debugDescription)
        button.tap()
    }

    private func assertEvent(_ event: String, in app: XCUIApplication) {
        let received = NSPredicate(format: "label CONTAINS %@", event)
        let expectation = XCTNSPredicateExpectation(predicate: received, object: app.staticTexts["preview.events"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, app.debugDescription)
    }
}
