//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerSK2Tests.swift
//
//  Created by César de la Vega on 9/1/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

// swiftlint:disable:next type_name
class TrialOrIntroPriceEligibilityCheckerSK2Tests: StoreKitConfigTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!
    var mockProductsManager: MockProductsManager!
    var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockSystemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                            platformFlavorVersion: "123",
                                            finishTransactions: true)

        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        let mockProductsManager = PartialMockProductsManager(systemInfo: mockSystemInfo)
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                        receiptParser: MockReceiptParser())
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let identityManager = MockIdentityManager(mockAppUserID: "app_user")
        trialOrIntroPriceEligibilityChecker =
        TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                            introEligibilityCalculator: mockIntroEligibilityCalculator,
                                            backend: mockBackend,
                                            identityManager: identityManager,
                                            operationDispatcher: mockOperationDispatcher,
                                            productsManager: mockProductsManager)
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckEligibilityAsync() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let products = ["product_id",
                        "com.revenuecat.monthly_4.99.1_week_intro",
                        "com.revenuecat.annual_39.99.2_week_intro",
                        "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.eligible,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.eligible,
                        "lifetime": IntroEligibilityStatus.unknown]

        let maybeEligibilities = await trialOrIntroPriceEligibilityChecker!.sk2CheckEligibility(products)
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == expected.count

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityNoAsync() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        let products = ["product_id",
                        "com.revenuecat.monthly_4.99.1_week_intro",
                        "com.revenuecat.annual_39.99.2_week_intro",
                        "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.eligible,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.eligible,
                        "lifetime": IntroEligibilityStatus.unknown]

        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.checkEligibility(productIdentifiers: products) { eligibilities in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())

        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == expected.count

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

}
