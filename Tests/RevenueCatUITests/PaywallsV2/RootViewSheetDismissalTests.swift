//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootViewSheetDismissalTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class RootViewSheetDismissalTests: TestCase {

    // MARK: - restoredPackageAfterSheetDismissal

    /// In a workflow context, dismissing the sheet without selecting a new package must restore
    /// the snapshot taken when the sheet opened — not fall back to the global workflow default.
    func testWorkflowContextRestoresSnapshotOnDismissal() {
        let snapshot = TestData.monthlyPackage
        let defaultPackage = TestData.annualPackage
        let workflowCtx = WorkflowPackageContext(selectedPackage: defaultPackage, packages: [defaultPackage, snapshot])

        let result = RootView.restoredPackageAfterSheetDismissal(
            workflowPackageContext: workflowCtx,
            packageBeforeOpeningSheet: snapshot,
            defaultPackage: defaultPackage
        )

        expect(result?.identifier) == snapshot.identifier
    }

    /// In a workflow context with no snapshot (sheet opened before any selection was cached),
    /// dismissal falls back to the step default.
    func testWorkflowContextFallsBackToDefaultWhenNoSnapshot() {
        let defaultPackage = TestData.annualPackage
        let workflowCtx = WorkflowPackageContext(selectedPackage: defaultPackage, packages: [defaultPackage])

        let result = RootView.restoredPackageAfterSheetDismissal(
            workflowPackageContext: workflowCtx,
            packageBeforeOpeningSheet: nil,
            defaultPackage: defaultPackage
        )

        expect(result?.identifier) == defaultPackage.identifier
    }

    /// Outside a workflow context the sheet always resets to the step default,
    /// even when a non-nil snapshot exists (it should be ignored).
    func testNonWorkflowContextAlwaysRestoresDefault() {
        let snapshot = TestData.monthlyPackage
        let defaultPackage = TestData.annualPackage

        let result = RootView.restoredPackageAfterSheetDismissal(
            workflowPackageContext: nil,
            packageBeforeOpeningSheet: snapshot,
            defaultPackage: defaultPackage
        )

        expect(result?.identifier) == defaultPackage.identifier
    }

    /// A nil default package (no packages in the offering) is a valid state; the result should be nil.
    func testWorkflowContextReturnsNilWhenBothSnapshotAndDefaultAreNil() {
        let workflowCtx = WorkflowPackageContext(selectedPackage: TestData.monthlyPackage, packages: [])

        let result = RootView.restoredPackageAfterSheetDismissal(
            workflowPackageContext: workflowCtx,
            packageBeforeOpeningSheet: nil,
            defaultPackage: nil
        )

        expect(result).to(beNil())
    }

}

#endif
