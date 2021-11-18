//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerTests.swift
//
//  Created by César de la Vega on 9/1/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class TrialOrIntroPriceEligibilityCheckerTests: StoreKitConfigTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!
    var mockProductsManager: MockProductsManager!
    var mockSystemInfo: MockSystemInfo!

    func setupSK1() throws {
        mockSystemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                            platformFlavorVersion: "123",
                                            finishTransactions: true)
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let identityManager = MockIdentityManager(mockAppUserID: "app_user")
        let mockProductsManager = MockProductsManager()
        trialOrIntroPriceEligibilityChecker =
        TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                            introEligibilityCalculator: mockIntroEligibilityCalculator,
                                            backend: mockBackend,
                                            identityManager: identityManager,
                                            operationDispatcher: mockOperationDispatcher,
                                            productsManager: mockProductsManager)
    }

    func setUpSK2WithError() throws {
        try super.setUpWithError()

        mockSystemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                            platformFlavorVersion: "123",
                                            finishTransactions: true)

        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let identityManager = MockIdentityManager(mockAppUserID: "app_user")
        let mockProductsManager = PartialMockProductsManager()
        trialOrIntroPriceEligibilityChecker =
        TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                            introEligibilityCalculator: mockIntroEligibilityCalculator,
                                            backend: mockBackend,
                                            identityManager: identityManager,
                                            operationDispatcher: mockOperationDispatcher,
                                            productsManager: mockProductsManager)
    }

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntCrash() throws {
        try setupSK1()
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { _ in
        }
    }

    func testSK1CheckTrialOrIntroPriceEligibilityFetchesAReceipt() throws {
        try setupSK1()
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { _ in
        }

        expect(self.receiptFetcher.receiptDataCalled) == true
    }

    func testSK1EligibilityIsCalculatedFromReceiptData() throws {
        try setupSK1()
        let stubbedEligibility = ["product_id": IntroEligibilityStatus.eligible]
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityResult = (stubbedEligibility, nil)

        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 1
    }

    func testSK1EligibilityIsFetchedFromBackendIfErrorCalculatingEligibility() throws {
        try setupSK1()
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityResult = ([:], stubbedError)

        let productId = "product_id"
        let stubbedEligibility = [productId: IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)]
        mockBackend.stubbedGetIntroEligibilityCompletionResult = (stubbedEligibility, nil)
        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 1
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.eligible

        expect(self.mockBackend.invokedGetIntroEligibilityCount) == 1
    }

    func testSK1ErrorFetchingFromBackendAfterErrorCalculatingEligibility() throws {
        try setupSK1()
        let productId = "product_id"

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityResult = ([:], stubbedError)

        mockBackend.stubbedGetIntroEligibilityCompletionResult = ([:], stubbedError)
        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 1
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.unknown
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckEligibilityAsync() async throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        try setUpSK2WithError()

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
        try setUpSK2WithError()

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
