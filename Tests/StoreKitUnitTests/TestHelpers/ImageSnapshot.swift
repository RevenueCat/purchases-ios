//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageSnapshot.swift
//
//  Created by Nacho Soto on 6/12/23.

import Foundation
import Nimble
import SnapshotTesting
import SwiftUI

#if swift(>=5.8)

/// - Parameter separateOSVersions: pass `true` if you want to generate separate snapshots for each version.
func haveValidSnapshot<Value>(
    as strategy: Snapshotting<Value, some Any>,
    named name: String? = nil,
    separateOSVersions: Bool = true,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    line: UInt = #line
) -> Nimble.Predicate<Value> {
    return Nimble.Predicate { actualExpression in
        guard let value = try actualExpression.evaluate() else {
            return PredicateResult(status: .fail, message: .fail("have valid snapshot"))
        }

        guard let errorMessage = verifySnapshot(
            matching: value,
            as: strategy,
            named: name,
            record: recording,
            timeout: timeout,
            file: file,
            testName: separateOSVersions
                ? CurrentTestCaseTracker.osVersionAndTestName
                : CurrentTestCaseTracker.sanitizedTestName,
            line: line
        ) else {
            return PredicateResult(bool: true, message: .fail("have valid snapshot"))
        }

        return PredicateResult(
            bool: false,
            message: .fail(errorMessage)
        )
    }
}

#endif
