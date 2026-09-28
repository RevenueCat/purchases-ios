//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallSideToolbarCloseUITests.swift
//
//  Created by Michael S. Muegel on 9/24/26.

import XCTest

/// Where a close button ends up is decided by the system toolbar, which unit tests cannot see.
///
/// The move only happens where the window supports a vertical toolbar, such as on iPhone Duo with
/// the iOS 27.1 SDK. Elsewhere the test that expects the move skips, so the suite passes on any
/// simulator. To run it, select the Duo:
/// `DEVELOPER_DIR=<Xcode 27.1>/Contents/Developer SCAN_DEVICE="iPhone Duo (27.1)"`.
final class PaywallSideToolbarCloseUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// A directly presented `PaywallView` can't tell a modal root from a pushed view, so without
    /// the opt-in the designed button stays where the paywall put it.
    func testDesignedCloseButtonStaysWithoutOptIn() throws {
        let app = self.launch(optsIn: false)

        let closeButtons = self.closeButtons(in: app)
        XCTAssertEqual(closeButtons.count, 1, app.debugDescription)
        self.assertInDesignedPosition(closeButtons.firstMatch, in: app)
    }

    func testOptInKeepsDesignedCloseButtonWithoutVerticalToolbar() throws {
        let app = self.launch(optsIn: true)
        try XCTSkipIf(
            self.supportsVerticalToolbar(app),
            "The window supports a vertical toolbar, so the close button moves."
        )

        let closeButtons = self.closeButtons(in: app)
        XCTAssertEqual(closeButtons.count, 1, app.debugDescription)
        self.assertInDesignedPosition(closeButtons.firstMatch, in: app)
    }

    /// The designed button leaves the layout and the toolbar's Close button replaces it, against a
    /// side edge rather than centered where the paywall designed it.
    func testOptInMovesCloseButtonToSideToolbar() throws {
        let app = self.launch(optsIn: true)
        try XCTSkipUnless(
            self.supportsVerticalToolbar(app),
            "Needs a window that supports a vertical toolbar, such as iPhone Duo with the iOS 27.1 SDK."
        )

        let closeButton = self.closeButtons(in: app).firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(
            self.closeButtons(in: app).count,
            1,
            "The designed close button is still in the layout. \(app.debugDescription)"
        )

        let window = app.windows.firstMatch.frame
        let distanceToSideEdge = min(closeButton.frame.minX - window.minX, window.maxX - closeButton.frame.maxX)
        XCTAssertLessThan(
            distanceToSideEdge,
            window.width / 4,
            "Close button at \(closeButton.frame) is not against a side edge of \(window)."
        )
    }

    // MARK: - Helpers

    private static let bodyCopy = "Everything you need, in one place."

    private func launch(optsIn: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "icon_only_button"
        if optsIn {
            app.launchEnvironment["PAYWALL_SIDE_TOOLBAR_CLOSE"] = "1"
        }
        app.launch()

        XCTAssertTrue(
            app.staticTexts[Self.bodyCopy].waitForExistence(timeout: 30),
            "Fixture did not render."
        )

        return app
    }

    private func closeButtons(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label == %@", "Close"))
    }

    /// Read from the fixture app, which reports its window's `toolbarVerticalEdge`.
    private func supportsVerticalToolbar(_ app: XCUIApplication) -> Bool {
        // Matches VerticalToolbarSupportMarkerView.identifier; the test bundle can't link it.
        let marker = app.descendants(matching: .any)["vertical_toolbar_support"]
        XCTAssertTrue(marker.waitForExistence(timeout: 10), "Vertical toolbar marker missing.")
        return marker.label == "supported"
    }

    /// The fixture centers its close button in the same stack as its body copy. Compared with the
    /// copy rather than the window, because iPhone Duo's safe areas are asymmetric and the stack is
    /// centered within them, not within the window.
    private func assertInDesignedPosition(
        _ closeButton: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let bodyCopy = app.staticTexts[Self.bodyCopy].frame
        XCTAssertEqual(
            closeButton.frame.midX,
            bodyCopy.midX,
            accuracy: 2,
            "Close button at \(closeButton.frame) is not centered over the body copy at \(bodyCopy).",
            file: file,
            line: line
        )
    }

}
