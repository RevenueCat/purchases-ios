//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CurrentTestCaseTracker.swift
//
//  Created by Nacho Soto on 12/22/21.

import XCTest

/// Helper class providing access to the currently executing XCTestCase instance, if any
final class CurrentTestCaseTracker: NSObject, XCTestObservation {

    static let shared = CurrentTestCaseTracker()

    private(set) var currentTestCase: XCTestCase?

    @objc func testCaseWillStart(_ testCase: XCTestCase) {
        currentTestCase = testCase
    }

    @objc func testCaseDidFinish(_ testCase: XCTestCase) {
        currentTestCase = nil
    }

}
