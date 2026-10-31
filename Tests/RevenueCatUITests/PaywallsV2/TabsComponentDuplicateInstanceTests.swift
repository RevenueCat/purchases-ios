//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentDuplicateInstanceTests.swift
//

@testable import RevenueCatUI
import XCTest

#if os(iOS)

/// Duplicate renderings of the same tabs must preserve each tab's manual selection.
@available(iOS 15.0, *)
@MainActor
final class TabsComponentDuplicateInstanceTests: TestCase {

    func testPW10DuplicateAndRecreatedViewsShareManualMemory() throws {
        let fixture = try PackageResolutionTestFixture()
        let dispose = try fixture.view().addToHierarchy()
        defer { dispose() }
        PackageResolutionTestFixture.settle()
        try fixture.select("$rc_annual", tab: "tab-1")
        fixture.tabs.tabControlContext.selectedTabId = "tab-2"
        PackageResolutionTestFixture.settle()
        try fixture.select("annual_xl", tab: "tab-2")

        let duplicateDispose = try fixture.view().addToHierarchy()
        defer { duplicateDispose() }
        PackageResolutionTestFixture.settle()
        XCTAssertEqual(fixture.context.package?.identifier, "annual_xl")
        fixture.tabs.tabControlContext.selectedTabId = "tab-1"
        PackageResolutionTestFixture.settle()
        XCTAssertEqual(fixture.context.package?.identifier, "$rc_annual")
        fixture.tabs.tabControlContext.selectedTabId = "tab-2"
        PackageResolutionTestFixture.settle()
        XCTAssertEqual(fixture.context.package?.identifier, "annual_xl")
    }

}

#endif
