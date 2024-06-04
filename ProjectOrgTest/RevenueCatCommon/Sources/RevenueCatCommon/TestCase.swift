//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestCase.swift
//
//  Created by Nacho Soto on 7/12/23.

import SnapshotTesting
import XCTest

// swiftlint:disable xctestcase_superclass

/// Parent class for all test cases
/// Provides automatic tracking of test cases using `CurrentTestCaseTracker` as well as snapshot testing helpers.
class TestCase: XCTestCase {

    @MainActor
    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)

        SnapshotTests.updateSnapshotsIfNeeded()
    }

    @MainActor
    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    // swiftlint:disable unneeded_override

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    @MainActor
    override func tearDown() {
        super.tearDown()
    }

    // swiftlint:enable unneeded_override

    // MARK: -

}

private enum SnapshotTests {

    private static var environmentVariableChecked = false

    static func updateSnapshotsIfNeeded() {
        guard !Self.environmentVariableChecked else { return }

        if ProcessInfo.processInfo.environment["CIRCLECI_TESTS_GENERATE_REVENUECAT_UI_SNAPSHOTS"] == "1" {
            isRecording = true
        }
    }

}
