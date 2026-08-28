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

    // MARK: - Package selection

    /// The state must be heard right after the offer's name, not after its pricing detail:
    /// a screen reader user should not have to sit through "$39.99 yearly, billed at ..." to
    /// learn whether the row is the selected one.
    func testSelectionStateIsAnnouncedAfterTheOfferName() throws {
        let app = self.launchDecorativeMedia()

        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Yearly")).firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(
            selected.label.hasPrefix("Yearly, Selected"),
            "Selection state should follow the name immediately, got: \(selected.label)"
        )

        let unselected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Monthly")).firstMatch
        XCTAssertTrue(
            unselected.label.hasPrefix("Monthly, Not selected"),
            "The unselected state must be spoken explicitly, got: \(unselected.label)"
        )
    }

    /// A card whose first text is hidden must not hand the state to it: that text renders
    /// nothing, so the state would be announced nowhere at all.
    func testSelectionStateSurvivesAHiddenFirstText() throws {
        let app = self.launchDecorativeMedia()

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Weekly")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 30), app.debugDescription)

        let announcesInLabel = card.label.contains("Not selected")
        let announcesInValue = (card.value as? String) == "Not selected"
        XCTAssertTrue(
            announcesInLabel || announcesInValue,
            "Selection state was announced nowhere. label: \(card.label), value: \(String(describing: card.value))"
        )
        XCTAssertFalse(
            card.label.hasPrefix("Hidden badge"),
            "The hidden text must not be the one carrying the state: \(card.label)"
        )
    }

    /// The state belongs to the label now, so it must not also be exposed as the row's value,
    /// or VoiceOver says it twice.
    func testSelectionStateIsNotAlsoAnnouncedAsAValue() throws {
        let app = self.launchDecorativeMedia()

        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Yearly")).firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 30))
        XCTAssertNotEqual(selected.value as? String, "Selected", "Selection state is announced twice.")
    }

    // MARK: - Harness control

    /// Element queries cannot answer "is this hidden from VoiceOver": XCUITest lists elements
    /// that carry `accessibilityHidden(true)`. This pins that down with plain SwiftUI images so
    /// the next person does not write an assertion that silently cannot fail — which is why the
    /// media tests below use `performAccessibilityAudit` instead.
    ///
    /// If this starts failing, XCUITest began honoring the modifier and element queries became
    /// usable for these assertions.
    func testElementQueriesListEvenHiddenImages() throws {
        let app = XCUIApplication()
        // Matches AccessibilityControlView.fixtureName in the app target, which the UI test
        // bundle does not link against.
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

    // MARK: - Decorative media (images, icons, backgrounds)

    /// Paywall media carries no labels, so anything left in the accessibility tree is announced
    /// as a bare "image". The audit counts exactly those, which makes it the oracle for what a
    /// screen reader would say. By default the fixture leaves three: the background image and
    /// the two free-standing feature checkmarks. The two package-card checkmarks are inside
    /// selector buttons, whose own labels describe them.
    func testDecorativeMediaAnnouncesIconsAndBackgroundByDefault() throws {
        let app = self.launchDecorativeMedia()

        XCTAssertEqual(
            try self.undescribedElementCount(in: app),
            3,
            "Default behavior changed: icons and background images are announced unless an app opts out."
        )
    }

    /// Hiding icons leaves the background image announced, so the two opt-outs stay independent.
    func testHidingIconsLeavesBackgroundAnnounced() throws {
        let app = self.launchDecorativeMedia(extraEnvironment: ["PAYWALL_HIDE_ICONS": "1"])

        XCTAssertEqual(
            try self.undescribedElementCount(in: app),
            1,
            "Expected only the background image to remain announced."
        )
    }

    /// Hiding images silences the background image while icons keep being announced.
    func testHidingImagesLeavesIconsAnnounced() throws {
        let app = self.launchDecorativeMedia(extraEnvironment: ["PAYWALL_HIDE_IMAGES": "1"])

        XCTAssertEqual(
            try self.undescribedElementCount(in: app),
            2,
            "Expected only the two free-standing feature icons to remain announced."
        )
    }

    /// Both opt-outs together leave nothing undescribed: no logo, no background, no checkmarks.
    func testHidingBothLeavesNothingUndescribed() throws {
        let app = self.launchDecorativeMedia(extraEnvironment: [
            "PAYWALL_HIDE_ICONS": "1",
            "PAYWALL_HIDE_IMAGES": "1"
        ])

        try app.performAccessibilityAudit(for: [.sufficientElementDescription])
    }

    // MARK: - Helpers

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

    private func launchDecorativeMedia(extraEnvironment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "decorative_media"
        for (key, value) in extraEnvironment {
            app.launchEnvironment[key] = value
        }
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Unlock all Sundial Features"].waitForExistence(timeout: 30),
            "Fixture did not render."
        )

        return app
    }

    /// How many elements the audit finds with no usable description — the unlabeled media a
    /// screen reader would announce as a bare "image". Counted with the closure form so the
    /// issues are tallied rather than thrown, letting a test assert on exactly how many remain.
    ///
    /// The background image loads over the network, so this settles first: asserting before it
    /// lands would count a paywall that has not finished rendering.
    private func undescribedElementCount(in app: XCUIApplication) throws -> Int {
        self.settle(app, seconds: 5)

        var count = 0
        try app.performAccessibilityAudit(for: [.sufficientElementDescription]) { _ in
            count += 1
            return true
        }

        return count
    }

    /// Lets async layout and image downloads land before measuring.
    private func settle(_ app: XCUIApplication, seconds: TimeInterval = 2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
        _ = app.images.count
    }


}
