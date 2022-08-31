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
//  Created by Nacho Soto on 5/10/22.

import SnapshotTesting
import XCTest

// swiftlint:disable xctestcase_superclass

/// Parent class for all test cases
/// Provides automatic tracking of test cases using `CurrentTestCaseTracker` as well as snapshot testing helpers.
class TestCase: XCTestCase {

    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)

        SnapshotTests.updateSnapshotsIfNeeded()
    }

    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    // MARK: - MainActor overrides

    // Note: these arent't required for Xcode 14+, but solve warnings prior to that.

    #if swift(<5.7)

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    @MainActor
    override func tearDown() {
        super.tearDown()
    }

    #endif

    // MARK: -

}

private enum SnapshotTests {

    private static var environmentVariableChecked = false

    static func updateSnapshotsIfNeeded() {
        guard !Self.environmentVariableChecked else { return }

        if ProcessInfo.processInfo.environment["CIRCLECI_TESTS_GENERATE_SNAPSHOTS"] == "true" {
            isRecording = true
        }
    }

}
