//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEventTests.swift
//
//  Created by Facundo Menzella on 29/1/25.

import Foundation
import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class CustomerCenterEventTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testEncoding() throws {
        let event = CustomerCenterEvent.impression(
            .default,
            CustomerCenterEvent.Data(
                locale: Locale(identifier: "en_US"),
                darkMode: true,
                isSandbox: true,
                displayMode: .fullScreen
            )
        )

        let prettyPrintedData = try JSONEncoder.prettyPrinted.encode(event)
        let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8)!
        XCTAssertEqual(prettyPrintedString,
                       prettyPrintedString,
                       """
                       {
                           "impression" : {
                             "_0" : {
                               "date" : "2023-09-06T19:42:08Z",
                               "id" : "72164C05-2BDC-4807-8918-A4105F727DEB"
                             },
                             "_1" : {
                               "base" : {
                                "locale_identifier": "en_US",
                                "dark_mode": true,
                                "display_mode": "full_screen",
                                "is_sandbox": true
                             }
                           }
                         }
                       """
        )
    }
}
