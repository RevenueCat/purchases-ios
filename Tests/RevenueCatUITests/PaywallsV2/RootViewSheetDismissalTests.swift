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

    func testRestoresSnapshotBeforeDefaultOnDismissal() {
        let snapshot = TestData.monthlyPackage
        let result = RootView.restoredPackageAfterSheetDismissal(
            packageBeforeOpeningSheet: snapshot,
            defaultPackage: TestData.annualPackage,
            sheetSelectedPackage: TestData.annualPackage,
            hasNonSheetPackages: true
        )
        expect(result?.identifier) == snapshot.identifier
    }

    func testFallsBackToDefaultWithoutSnapshot() {
        let defaultPackage = TestData.annualPackage
        let result = RootView.restoredPackageAfterSheetDismissal(
            packageBeforeOpeningSheet: nil,
            defaultPackage: defaultPackage,
            sheetSelectedPackage: TestData.monthlyPackage,
            hasNonSheetPackages: true
        )
        expect(result?.identifier) == defaultPackage.identifier
    }

    func testReturnsNilWhenSnapshotAndDefaultAreNil() {
        let result = RootView.restoredPackageAfterSheetDismissal(
            packageBeforeOpeningSheet: nil,
            defaultPackage: nil,
            sheetSelectedPackage: nil,
            hasNonSheetPackages: true
        )
        expect(result).to(beNil())
    }

    func testKeepsSheetSelectionWhenRootHasNoPackages() {
        let selectedInSheet = TestData.annualPackage
        let result = RootView.restoredPackageAfterSheetDismissal(
            packageBeforeOpeningSheet: TestData.monthlyPackage,
            defaultPackage: TestData.monthlyPackage,
            sheetSelectedPackage: selectedInSheet,
            hasNonSheetPackages: false
        )
        expect(result?.identifier) == selectedInSheet.identifier
    }

}

#endif

#if os(iOS)

@available(iOS 15.0, *)
extension RootViewSheetDismissalTests {

    @MainActor
    func testPW11DismissalRestoresRootChoiceAheadOfTabDefault() async throws {
        let fixture = try PackageResolutionTestFixture(competingDefaults: true)
        let dispose = try fixture.view().addToHierarchy()
        defer { dispose() }
        try await PackageResolutionTestFixture.settlePresentation()
        fixture.tabs.tabControlContext.selectedTabId = "tab-2"
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(fixture.context.package?.identifier, "monthly_xl")

        let rootPackage = try XCTUnwrap(fixture.offering.package(identifier: "$rc_monthly"))
        fixture.context.update(package: rootPackage, variableContext: fixture.context.variableContext)
        try await PackageResolutionTestFixture.settlePresentation()
        let snapshot = fixture.context.package
        let variables = fixture.context.variableContext
        let tabsState = fixture.context.tabsState(for: fixture.tabs)
        let tabContext = try XCTUnwrap(tabsState.contextsByTabId["tab-2"])
        XCTAssertEqual(snapshot?.identifier, rootPackage.identifier)
        XCTAssertEqual(fixture.context.manuallySelectedPackage?.identifier, rootPackage.identifier)
        XCTAssertTrue(tabsState.didUserSelectPackage)
        XCTAssertEqual(tabsState.parentOwnedPackage?.identifier, rootPackage.identifier)
        XCTAssertNil(tabContext.package)

        let sheetValidator = try XCTUnwrap(fixture.state.rootViewModel.stackViewModel.viewModels.compactMap {
            if case .button(let button) = $0 { return button.sheetPackageValidator }
            return nil
        }.first)
        let sheetContext = fixture.context.activateSheet(validator: sheetValidator, selectionContext: .provisional)
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(sheetContext.package?.identifier, "annual_xl")
        XCTAssertEqual(fixture.context.package?.identifier, "annual_xl")
        XCTAssertEqual(fixture.context.manuallySelectedPackage?.identifier, rootPackage.identifier)
        XCTAssertEqual(tabsState.parentOwnedPackage?.identifier, rootPackage.identifier)

        fixture.context.update(
            package: RootView.restoredPackageAfterSheetDismissal(
                packageBeforeOpeningSheet: snapshot,
                defaultPackage: fixture.state.viewModelFactory.packageValidator
                    .defaultSelectedPackage(in: .provisional),
                sheetSelectedPackage: sheetContext.package,
                hasNonSheetPackages: true
            ),
            variableContext: variables,
            isReconcile: true
        )
        fixture.context.presentedSheetContext = nil
        try await PackageResolutionTestFixture.settlePresentation()

        XCTAssertEqual(fixture.context.package?.identifier, "$rc_monthly")
        XCTAssertNil(tabContext.package, "The tab default must not replace the restored root choice")
        XCTAssertEqual(fixture.context.variableContext.exactMostExpensivePricePerMonth,
                       variables.exactMostExpensivePricePerMonth)
    }

}

#endif
