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

    /// XCUITest lists elements that carry `accessibilityHidden(true)`, so element queries cannot
    /// answer "is this hidden from VoiceOver". Fails once XCUITest starts honoring the modifier.
    func testElementQueriesListEvenHiddenImages() throws {
        let app = XCUIApplication()
        // Matches AccessibilityHiddenControlView.fixtureName; the test bundle can't link it.
        app.launchEnvironment["PAYWALL_FIXTURE"] = "a11y_control"
        app.launch()

        XCTAssertTrue(app.staticTexts["Control"].waitForExistence(timeout: 30))

        let identifiers = app.images.allElementsBoundByIndex.map { $0.identifier }
        XCTAssertTrue(identifiers.contains("star.fill"), "Visible control image missing.")
        XCTAssertTrue(
            identifiers.contains("heart.fill"),
            "XCUITest now hides accessibilityHidden elements; element queries can be trusted again."
        )
        XCTAssertTrue(
            identifiers.contains("bolt.fill"),
            "XCUITest now hides collapsed-and-hidden elements; element queries can be trusted again."
        )
    }

    // MARK: - Spoken text

    /// The spoken variant is built from the source copy, so it still carries markdown when it
    /// reaches the label. What VoiceOver receives must be the words, not the syntax.
    func testSpokenLabelDropsMarkdownSyntax() throws {
        let app = self.launchSpokenText()

        // The paragraph carrying both a link and a price: only that shape gets a spoken label
        // applied over text that still contains markdown.
        let paragraph = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "terms of service", "monthly")
        ).firstMatch
        XCTAssertTrue(paragraph.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertFalse(paragraph.label.contains("["), "Markdown reached VoiceOver: \(paragraph.label)")
        XCTAssertFalse(paragraph.label.contains("https://"), "A link URL is spoken: \(paragraph.label)")
        XCTAssertFalse(paragraph.label.contains("<u>"), "Underline tags are spoken: \(paragraph.label)")
    }

    /// The displayed price keeps "/mo"; only what is spoken expands.
    func testSpokenLabelExpandsThePeriod() throws {
        let app = self.launchSpokenText()

        let price = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "monthly")
        ).firstMatch
        XCTAssertTrue(price.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertFalse(price.label.contains("/mo"), "Still spoken as slash mo: \(price.label)")
    }

    private func launchSpokenText() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "spoken_text_and_links"
        app.launchEnvironment["PAYWALL_VOICE_OVER"] = "1"
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Spoken text and links"].waitForExistence(timeout: 30),
            "Fixture did not render."
        )

        return app
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
