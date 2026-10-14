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

    private func launch(mode: String, configured: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "customer_center_preview"
        app.launchEnvironment["PREVIEW_PAYWALL"] = mode
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
