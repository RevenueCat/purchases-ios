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

    /// Extracts the name of the current running test.
    ///
    /// Example: extracts `testLoginCachesForSameUserIDs`
    /// from `-[BackendTests testLoginCachesForSameUserIDs]`
    static var sanitizedTestName: String {
        guard let test = Self.shared.currentTestCase else {
            fatalError("No test currently running")
        }

        return test.sanitizedName
    }

}

private extension XCTestCase {

    var sanitizedName: String {
        let className = String(describing: type(of: self))
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: "-\\[\(className) (?<name>.*)\\]")

        let range = NSRange(location: 0, length: self.name.utf8.count)

        let nameRange = regex
            .firstMatch(in: self.name, options: [], range: range)!
            .range(withName: "name")

        let start = self.name.index(name.startIndex, offsetBy: nameRange.location)
        return String(self.name[start..<self.name.index(start, offsetBy: nameRange.length)])
    }

}
