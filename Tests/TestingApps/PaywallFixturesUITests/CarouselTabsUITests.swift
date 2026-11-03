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

final class CarouselTabsUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testEachCarouselRestoresItsPageAfterTabChanges() {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "carousel_tabs"
        app.launch()

        self.assertPage("Annual page 0", in: app)
        self.swipeForward(from: "Annual page 0", in: app)
        self.assertPage("Annual page 1", in: app)
        self.swipeForward(from: "Annual page 1", in: app)
        self.assertPage("Annual page 2", in: app)

        app.buttons["Monthly"].firstMatch.tap()
        self.assertPage("Monthly page 1", in: app)
        self.swipeForward(from: "Monthly page 1", in: app)
        self.assertPage("Monthly page 2", in: app)
        self.swipeForward(from: "Monthly page 2", in: app)
        self.assertPage("Monthly page 0", in: app)

        app.buttons["Annual"].firstMatch.tap()
        self.assertPage("Annual page 2", in: app)
        app.buttons["Monthly"].firstMatch.tap()
        self.assertPage("Monthly page 0", in: app)
    }

    private func assertPage(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let centered = NSPredicate { _, _ in
            Self.centeredPage(label, in: app) != nil
        }
        let result = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: centered, object: nil)],
            timeout: 5
        )
        XCTAssertEqual(result, .completed, "Expected \(label) at the center of the carousel.", file: file, line: line)
    }

    private func swipeForward(from label: String, in app: XCUIApplication) {
        guard let page = Self.centeredPage(label, in: app) else {
            XCTFail("No centered page for \(label)")
            return
        }
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0))
            .withOffset(CGVector(dx: 0, dy: page.frame.midY))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0))
            .withOffset(CGVector(dx: 0, dy: page.frame.midY))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private static func centeredPage(_ label: String, in app: XCUIApplication) -> XCUIElement? {
        app.staticTexts.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex.first {
            $0.isHittable && abs($0.frame.midX - app.frame.midX) < 2
        }
    }

}
