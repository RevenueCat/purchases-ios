//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallAccessibilityUITests.swift
//
//  Created by Facundo Menzella on 8/5/26.

import XCTest

/// Asserts against the real accessibility tree, which SwiftUI only builds for an assistive
/// technology client. Unit tests cannot see it, so screen reader behavior is verified here.
final class PaywallAccessibilityUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// An icon-only button has no text to announce, so without a derived label VoiceOver reads it
    /// as a bare "button".
    func testIconOnlyButtonIsAnnounced() throws {
        let app = self.launch(fixture: "icon_only_button")

        XCTAssertTrue(
            app.buttons["Close"].waitForExistence(timeout: 10),
            "No element in the accessibility tree is labelled \"Close\"."
        )
    }

    /// Catches the whole class of bug rather than one string: `.sufficientElementDescription` fails
    /// on any element whose description is missing or unhelpful, including components that do not
    /// exist yet. Deliberately does not assert on the label first, so the audit itself is what
    /// fails when a button stops being announced.
    func testIconOnlyButtonPaywallDescribesEveryElement() throws {
        let app = self.launch(fixture: "icon_only_button")

        try app.performAccessibilityAudit(for: [.sufficientElementDescription])
    }

    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = fixture
        app.launch()

        // Waits on the paywall's body copy rather than the button, so a test asserting on the
        // button's label is not gated by that same label.
        XCTAssertTrue(
            app.staticTexts["Everything you need, in one place."].waitForExistence(timeout: 30),
            "Fixture did not render."
        )

        return app
    }

}
