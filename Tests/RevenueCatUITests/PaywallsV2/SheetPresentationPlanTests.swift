//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SheetPresentationPlanTests.swift
//
//  Created by Facundo Menzella on 2026-09-07.

@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class SheetPresentationPlanTests: TestCase {

    // MARK: - First pass is hidden

    func testRequestedSheetIsHiddenUntilItHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-a", settledSheetID: nil)

        XCTAssertFalse(plan.isPresented)
    }

    func testRequestedSheetIsPresentedOnceItHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-a", settledSheetID: "sheet-a")

        XCTAssertTrue(plan.isPresented)
    }

    func testSwitchingToAnotherSheetHidesItUntilThatOneHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-b", settledSheetID: "sheet-a")

        XCTAssertFalse(plan.isPresented)
    }

    func testNothingRequestedIsNotPresented() {
        let plan = SheetPresentationPlan.make(requestedSheetID: nil, settledSheetID: "sheet-a")

        XCTAssertFalse(plan.isPresented)
    }

    // MARK: - Settled id bookkeeping

    func testDismissingClearsTheSettledSheet() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: nil, previous: "sheet-a"))
    }

    func testRequestingADifferentSheetClearsTheSettledSheet() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-b", previous: "sheet-a"))
    }

    func testReRequestingTheSettledSheetKeepsItSettled() {
        XCTAssertEqual(
            SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-a", previous: "sheet-a"),
            "sheet-a"
        )
    }

    func testRequestingASheetWithNothingSettledStaysUnsettled() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-a", previous: nil))
    }

}

#endif
