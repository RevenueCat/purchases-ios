//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SnapshotTests.swift
//
//  Created by Nacho Soto on 5/17/23.

import Foundation
import SnapshotTesting

enum SnapshotTests {

    private static var environmentVariableChecked = false

    static func updateSnapshotsIfNeeded() {
        guard !Self.environmentVariableChecked else { return }

        if ProcessInfo.processInfo.environment["CIRCLECI_TESTS_GENERATE_SNAPSHOTS"] == "1" {
            isRecording = true
        }
    }

}
