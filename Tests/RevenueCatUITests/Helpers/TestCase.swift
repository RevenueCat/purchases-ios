//
//  TestCase.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

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

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    @MainActor
    override func tearDown() {
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
