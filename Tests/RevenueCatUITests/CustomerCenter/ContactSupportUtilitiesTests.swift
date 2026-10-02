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
@_spi(Internal) import RevenueCat
@_spi(Internal)@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class ContactSupportUtilitiesTest: TestCase {

    private let support: CustomerCenterConfigData.Support = .init(
        email: "support@example.com",
        shouldWarnCustomerToUpdate: false,
        displayPurchaseHistoryLink: false,
        displayUserDetailsSection: false,
        displayVirtualCurrencies: false
    )
    private let localization: CustomerCenterConfigData.Localization = .init(locale: "en_US", localizedStrings: [:])

    func testSupportEmailBodyWithDefaultDataIsCorrect() {
        let body = support.calculateBody(localization, purchasesProvider: CustomerCenterPurchases())
        let initialBody = """
        Please describe your issue or question.

        ---------------------------
        """

        expect(body).to(contain(initialBody))
        expect(body).to(contain("- RC User ID: Unknown"))
        expect(body).to(contain("- App Version:"))
        expect(body).to(contain("- StoreFront Country Code: Unknown"))
        expect(body).to(contain("- Device:"))
        expect(body).to(contain("- OS Version:"))

    }

    #if os(macOS)
    func testBodyIncludesTheMacOSVersionAndHardwareModel() {
        // Same setup as the test above; only the assertions differ.
        let body = support.calculateBody(localization, purchasesProvider: CustomerCenterPurchases())

        expect(body).toNot(contain("- Device: Unknown"))
        expect(body).toNot(contain("- OS Version: Unknown"))
        expect(body).to(match("- OS Version: \\d+\\.\\d+"))
    }
    #endif

    func testSupportEmailBodyWithGivenDataIsCorrect() {
        let givenData = [("test1", "test2"), ("test3", "test4")]
        let body = support.calculateBody(localization,
                                         dataToInclude: givenData,
                                         purchasesProvider: CustomerCenterPurchases())
        let expectedBody = """
        Please describe your issue or question.

        ---------------------------
        - test1: test2
        - test3: test4
        """

        expect(body).to(equal(expectedBody))
    }

}
