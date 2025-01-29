//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterAnswerSubmittedEventTests.swift
//
//  Created by Facundo Menzella on 29/1/25.

import Foundation
import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class CustomerCenterAnswerSubmittedEventTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testEncoding() throws {
        let event = CustomerCenterAnswerSubmittedEvent.answerSubmitted(
            .default,
            CustomerCenterAnswerSubmittedEvent.Data(
                locale: Locale(identifier: "en_US"),
                darkMode: true,
                isSandbox: true,
                displayMode: .fullScreen,
                path: .cancel,
                url: URL(string: "revenuecat.com"),
                surveyOptionID: "surveyOptionID",
                surveyOptionTitleKey: "surveyOptionTitleKey",
                revisionID: 1
            )
        )

        let prettyPrintedData = try JSONEncoder.prettyPrinted.encode(event)
        let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8)!
        XCTAssertEqual(prettyPrintedString,
                       prettyPrintedString,
                       """
                       {
                           "answer_submitted" : {
                             "_0" : {
                               "date" : "2023-09-06T19:42:08Z",
                               "id" : "72164C05-2BDC-4807-8918-A4105F727DEB"
                             },
                             "_1" : {
                               "base" : {
                                 "dark_mode" : true,
                                 "display_mode" : "full_screen",
                                 "is_sandbox" : true,
                                 "locale_identifier" : "en_US"
                               },
                               "path" : "CANCEL",
                               "revision_id" : 1,
                               "survey_option_id" : "surveyOptionID",
                               "survey_option_title_key" : "surveyOptionTitleKey",
                               "url" : "revenuecat.com"
                             }
                           }
                         }
                       """
        )
    }

    // MARK: -

    private static let eventCreationData: CustomerCenterEventCreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )
}
