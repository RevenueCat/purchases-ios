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

final class NativeNavigationUITests: XCTestCase {
    private let backIdentifier = "RevenueCat.NativePaywallBack"
    private let closeIdentifier = "RevenueCat.NativePaywallClose"

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    #if os(iOS)
    func testNativeWorkflowControlsPreventCallerPopAtRootAndLaterPages() {
        let app = self.launch("native_workflow_navigation")
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        app.buttons["Continue"].tap()
        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        self.assertNativeControls(in: app, back: true, close: true)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        // Workflow Back must not pop the caller's screen while workflow history exists.
        start.press(forDuration: 0.1, thenDragTo: end)
        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        app.buttons[self.backIdentifier].tap()
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        self.assertNativeControls(in: app, back: false, close: true)
        // At the root, native Close still owns the exit instead of exposing the caller's Back.
        start.press(forDuration: 0.1, thenDragTo: end)
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        self.assertNativeControls(in: app, back: false, close: true)
        app.buttons[self.closeIdentifier].tap()
        self.assertVisible(app.staticTexts["Paywall dismissed"], in: app)
    }
    #endif

    #if os(iOS)
    func testInlineSheetKeepsWorkflowBackDisabledWithoutRestoringCallerBack() {
        let app = self.launch("native_workflow_navigation")
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        app.buttons["Continue"].tap()
        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        self.assertNativeControls(in: app, back: true, close: true)
        let detailBodyTop = app.staticTexts["Workflow detail"].frame.minY
        app.buttons["Open inline sheet"].tap()
        self.assertVisible(app.buttons["Designed sheet Close"], in: app)
        let suspended = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let back = app.buttons[self.backIdentifier]
            let close = app.buttons[self.closeIdentifier]
            return back.exists && !back.isEnabled && close.exists && !close.isEnabled
                && !app.buttons["BackButton"].exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [suspended], timeout: 10), .completed, app.debugDescription)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        self.assertVisible(app.buttons["Designed sheet Close"], in: app)
        app.buttons["Designed sheet Close"].tap()
        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        self.assertNativeControls(in: app, back: true, close: true)
        XCTAssertEqual(app.staticTexts["Workflow detail"].frame.minY, detailBodyTop,
                       accuracy: 1, app.debugDescription)
        app.buttons[self.backIdentifier].tap()
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        app.buttons[self.closeIdentifier].tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 10), app.debugDescription)
    }
    #endif

    func testNativeBackNavigatesWithinWorkflowWithoutPoppingCallerNavigation() {
        let app = self.launch("native_workflow_navigation")
        self.assertWorkflowNavigation(in: app)
    }

    func testSinglePageNativeBackDismissesWithoutCallerBack() {
        let app = self.launch("native_inline_sheet")
        self.assertVisible(app.staticTexts["Outer paywall"], in: app)
        self.assertNativeControls(in: app, back: false, close: true)
        app.buttons[self.closeIdentifier].tap()
        self.assertVisible(app.staticTexts["Paywall dismissed"], in: app)
    }

    func testNativeBackAndCloseInSheetPresentation() {
        let app = self.launch("native_workflow_navigation", presentation: "sheet")
        self.assertWorkflowNavigation(in: app)
    }

    #if os(iOS)
    func testNativeBackAndCloseInFullScreenPresentation() {
        let app = self.launch("native_workflow_navigation", presentation: "full_screen")
        self.assertWorkflowNavigation(in: app)
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    func testNativeWorkflowRemainsInteractiveAfterIPadRotation() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = self.launch("native_workflow_navigation")
        guard app.windows.firstMatch.frame.width >= 768 else { throw XCTSkip("Requires an iPad window") }
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed, app.debugDescription)
        self.assertWorkflowNavigation(in: app)
    }
    #endif

    #if os(iOS)
    func testEmbeddedCarouselCloseDismissesFromEachPage() {
        self.assertCarouselCloseDismisses(native: false)
    }

    func testNativeCarouselCloseDismissesFromEachPage() {
        self.assertCarouselCloseDismisses(native: true)
    }

    private func assertCarouselCloseDismisses(native: Bool) {
        for page in 1...5 {
            let app = self.launch("native_inline_sheet", presentation: "sheet", carouselNative: native)
            self.assertVisible(app.staticTexts["Carousel page 1"], in: app)
            for previous in 1..<page {
                let title = app.staticTexts["Carousel page \(previous)"]
                let origin = app.coordinate(withNormalizedOffset: .zero)
                let width = app.windows.firstMatch.frame.width
                let start = origin.withOffset(CGVector(dx: width * 0.8, dy: title.frame.midY))
                let end = origin.withOffset(CGVector(dx: width * 0.2, dy: title.frame.midY))
                start.press(forDuration: 0.05, thenDragTo: end)
                self.assertVisible(app.staticTexts["Carousel page \(previous + 1)"], in: app)
            }
            let close = app.buttons[native ? self.closeIdentifier : "Carousel Close \(page)"]
            self.assertVisible(close, in: app)
            self.assertNativeControls(in: app, back: false, close: native)
            if native {
                for embeddedPage in 1...5 {
                    XCTAssertFalse(app.buttons["Carousel Close \(embeddedPage)"].exists,
                                   "Every opted-in button must be replaced, including offscreen pages")
                }
            }
            close.tap()
            self.assertVisible(app.staticTexts["Paywall dismissed"], in: app)
            app.terminate()
        }
    }

    #endif

    private func assertWorkflowNavigation(in app: XCUIApplication) {
        self.assertVisible(app.staticTexts["Workflow root"], in: app)
        self.assertNativeControls(in: app, back: false, close: true)
        self.assertBodyBelowNavigation(in: app, title: "Workflow root", button: "Continue")
        app.buttons["Continue"].tap()

        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        self.assertNativeControls(in: app, back: true, close: true)
        let back = app.buttons[self.backIdentifier]
        XCTAssertTrue(back.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(back.isHittable, app.debugDescription)
        XCTAssertTrue(app.buttons[self.closeIdentifier].isHittable, app.debugDescription)
        XCTAssertFalse(app.buttons["Designed Back"].exists, app.debugDescription)
        XCTAssertFalse(app.buttons["Designed Close"].exists, app.debugDescription)
        // This pushed paywall replaces the caller's automatic Back while the workflow has history.
        XCTAssertEqual(Set(app.buttons.allElementsBoundByIndex.filter {
            $0.isHittable && !["Continue without Close", "Open inline sheet"].contains($0.label)
        }.map { $0.identifier }),
                       Set([self.backIdentifier, self.closeIdentifier]), app.debugDescription)
        self.assertBodyBelowNavigation(in: app, title: "Workflow detail", button: "Continue without Close")
        let detailBodyTop = app.staticTexts["Workflow detail"].frame.minY
        app.buttons["Continue without Close"].tap()
        self.assertVisible(app.staticTexts["Workflow without Close"], in: app)
        self.assertNativeControls(in: app, back: true, close: false)
        XCTAssertFalse(app.buttons[self.closeIdentifier].exists, app.debugDescription)
        XCTAssertTrue(back.isHittable, app.debugDescription)
        XCTAssertFalse(app.buttons["BackButton"].exists, app.debugDescription)
        // A native-only 120-point header must collapse to the same body position as the headerless page.
        XCTAssertEqual(app.staticTexts["Workflow without Close"].frame.minY, detailBodyTop,
                       accuracy: 1, app.debugDescription)
        back.tap()
        self.assertVisible(app.staticTexts["Workflow detail"], in: app)
        self.assertNativeControls(in: app, back: true, close: true)
        XCTAssertTrue(app.buttons[self.closeIdentifier].isHittable, app.debugDescription)
        XCTAssertFalse(app.buttons["Designed Close"].exists, app.debugDescription)
        back.tap()

        self.assertVisible(app.buttons["Continue"], in: app)
        self.assertNativeControls(in: app, back: false, close: true)
        let rootText = app.staticTexts["Workflow root"]
        XCTAssertTrue(rootText.exists, app.debugDescription)
        XCTAssertGreaterThan(rootText.frame.width, 0, app.debugDescription)
        XCTAssertGreaterThan(rootText.frame.height, 0, app.debugDescription)
        XCTAssertEqual(rootText.frame.minY, detailBodyTop, accuracy: 1, app.debugDescription)
        self.assertBodyBelowNavigation(in: app, title: "Workflow root", button: "Continue")
        XCTAssertFalse(rootText.frame.intersects(app.buttons[self.closeIdentifier].frame), app.debugDescription)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Workflow root after native Back"
        screenshot.lifetime = .keepAlways
        self.add(screenshot)
        let frames = XCTAttachment(string: "Root: \(rootText.frame)\nContinue: \(app.buttons["Continue"].frame)"
            + "\nClose: \(app.buttons[self.closeIdentifier].frame)\n\(app.debugDescription)")
        frames.name = "Workflow root accessibility frames"
        frames.lifetime = .keepAlways
        self.add(frames)
        XCTAssertFalse(app.buttons["Continue"].frame.intersects(app.buttons[self.closeIdentifier].frame),
                       app.debugDescription)
        XCTAssertFalse(app.buttons[self.backIdentifier].exists, app.debugDescription)
        XCTAssertFalse(app.buttons["Show native paywall"].isHittable, app.debugDescription)
        XCTAssertTrue(app.buttons[self.closeIdentifier].isHittable, app.debugDescription)
        app.buttons[self.closeIdentifier].tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 10), app.debugDescription)
    }

    func testInlineSheetKeepsItsDesignedCloseAndRestoresOuterNativeClose() {
        self.assertInlineSheetClose(badged: false)
    }

    func testBadgeBackInInlineSheetDismissesOnlyTheSheet() {
        self.assertInlineSheetClose(badged: true)
    }

    func testEmbeddedBadgeBackDismissesPaywall() {
        let app = self.launch("native_inline_sheet", badgeNative: false)
        self.assertVisible(app.staticTexts["Outer paywall"], in: app)
        self.assertNativeControls(in: app, back: false, close: false)
        app.buttons["Designed outer Close"].tap()
        self.assertVisible(app.staticTexts["Paywall dismissed"], in: app)
    }

    private func assertInlineSheetClose(badged: Bool) {
        let app = self.launch("native_inline_sheet", badgeNative: badged ? true : nil)
        let outerClose = app.buttons[self.closeIdentifier]
        XCTAssertTrue(outerClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(outerClose.isHittable, app.debugDescription)
        app.buttons["Open inline sheet"].tap()

        let sheetClose = app.buttons["Designed sheet Close"]
        XCTAssertTrue(sheetClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(sheetClose.isHittable, app.debugDescription)
        let suspended = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == false"), object: outerClose
        )
        XCTAssertEqual(XCTWaiter.wait(for: [suspended], timeout: 10), .completed, app.debugDescription)
        XCTAssertFalse(app.buttons[self.backIdentifier].exists, app.debugDescription)
        sheetClose.tap()

        XCTAssertTrue(outerClose.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(outerClose.isHittable, app.debugDescription)
        XCTAssertTrue(app.staticTexts["Outer paywall"].exists, app.debugDescription)
        XCTAssertFalse(sheetClose.exists, app.debugDescription)
        XCTAssertFalse(app.staticTexts["Paywall dismissed"].exists, app.debugDescription)
        outerClose.tap()
        XCTAssertTrue(app.staticTexts["Paywall dismissed"].waitForExistence(timeout: 10), app.debugDescription)
    }

    private func assertBodyBelowNavigation(in app: XCUIApplication, title: String, button: String) {
        // The fixture has no authored top padding. Its body must respect the whole native bar,
        // even when centered text would not intersect the trailing Close button horizontally.
        let belowNavigation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let navigationBar = app.navigationBars["Native paywall"]
            let text = app.staticTexts[title]
            let action = app.buttons[button]
            return navigationBar.exists && navigationBar.frame.height > 0 && text.exists && action.exists
                && text.frame.minY >= navigationBar.frame.maxY - 1
                && action.frame.minY >= navigationBar.frame.maxY - 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [belowNavigation], timeout: 10), .completed, app.debugDescription)
    }

    private func assertNativeControls(in app: XCUIApplication, back: Bool, close: Bool) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let backButton = app.buttons[self.backIdentifier]
            let closeButton = app.buttons[self.closeIdentifier]
            return app.buttons.matching(identifier: self.backIdentifier).count == (back ? 1 : 0)
                && app.buttons.matching(identifier: self.closeIdentifier).count == (close ? 1 : 0)
                && (!back || (backButton.isEnabled && backButton.isHittable))
                && (!close || (closeButton.isEnabled && closeButton.isHittable))
                && (!(back || close) || !app.buttons["BackButton"].exists)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed, app.debugDescription)
    }

    private func launch(
        _ fixture: String, presentation: String = "push", carouselNative: Bool? = nil, badgeNative: Bool? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = fixture
        app.launchEnvironment["PAYWALL_NATIVE_PRESENTATION"] = presentation
        if let carouselNative {
            app.launchEnvironment["PAYWALL_CAROUSEL_BUTTONS"] = carouselNative ? "native" : "embedded"
        }
        if let badgeNative {
            app.launchEnvironment["PAYWALL_BADGE_BUTTONS"] = badgeNative ? "native" : "embedded"
        }
        app.launch()
        let showPaywall = app.buttons["Show native paywall"]
        XCTAssertTrue(showPaywall.waitForExistence(timeout: 30), app.debugDescription)
        showPaywall.tap()
        return app
    }

    private func assertVisible(_ element: XCUIElement, in app: XCUIApplication) {
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"),
                                               object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 10), .completed, app.debugDescription)
    }
}
