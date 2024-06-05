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

    private(set) var logger: TestLogHandler!

    /// Called at the beginning of every test, but it can be manually used
    /// before calling `super.setUp()` in case a test needs to verify logs generated early in the lifetime.
    final func initializeLogger() {
        guard self.logger == nil else { return }

        self.logger = TestLogHandler(capacity: 1000)
    }

    @MainActor
    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)

        SnapshotTests.updateSnapshotsIfNeeded()
    }

    @MainActor
    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.initializeLogger()
    }

    @MainActor
    override func tearDown() {
        self.logger = nil

        super.tearDown()
    }

    // MARK: -

}

private enum SnapshotTests {

    private static var environmentVariableChecked = false

    static func updateSnapshotsIfNeeded() {
        guard !Self.environmentVariableChecked else { return }

        if ProcessInfo.processInfo.environment["CIRCLECI_TESTS_GENERATE_SNAPSHOTS"] == "1" {
            isRecording = true
        }
    }

}
