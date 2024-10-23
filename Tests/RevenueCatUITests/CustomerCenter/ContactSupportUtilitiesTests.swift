//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterSupportUtilities.swift
//
//  Created by Antonio Rico Diez on 2024-10-23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

class ContactSupportUtilitiesTest: TestCase {

    private let support: CustomerCenterConfigData.Support = .init(email: "support@example.com")
    private let localization: CustomerCenterConfigData.Localization = .init(locale: "en_US", localizedStrings: [:])

    func testSupportEmailBodyWithDefaultDataIsCorrect() {
        let body = support.calculateBody(localization)
        let expectedBody = """
        Please describe your issue or question.

        ---------------------------
        Extra information:
        - RCUserID: Unknown
        - StoreFront Country Code: Unknown
        - App Version: 16.0
        - iOS Version: 18.0
        """

        expect(body).to(equal(expectedBody))
    }

    func testSupportEmailBodyWithGivenDataIsCorrect() {
        let givenData = [("test1", "test2"), ("test3", "test4")]
        let body = support.calculateBody(localization, dataToInclude: givenData)
        let expectedBody = """
        Please describe your issue or question.

        ---------------------------
        Extra information:
        - test1: test2
        - test3: test4
        """

        expect(body).to(equal(expectedBody))
    }

}
