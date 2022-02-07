//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerSK1Tests.swift
//
//  Created by César de la Vega on 9/1/21.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

// swiftlint:disable:next type_name
class TrialOrIntroPriceEligibilityCheckerSK1Tests: StoreKitConfigTestCase {

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
        self.mockProductsManager = MockProductsManager(systemInfo: mockSystemInfo)
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

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntCrash() throws {
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { _ in
        }
    }

    func testSK1CheckTrialOrIntroPriceEligibilityDoesntFetchAReceipt() throws {
        self.receiptFetcher.shouldReturnReceipt = false

        expect(self.receiptFetcher.receiptDataCalled) == false

        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { _ in }

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .never
    }

    func testSK1EligibilityIsCalculatedFromReceiptData() throws {
        let stubbedEligibility = ["product_id": IntroEligibilityStatus.eligible]
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = (stubbedEligibility, nil)

        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([]) { (receivedEligibilities) in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == 1
    }

    func testSK1EligibilityIsFetchedFromBackendIfErrorCalculatingEligibilityAndStoreKitDoesNotHaveIt() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = Set()
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        let productId = "product_id"
        let stubbedEligibility = [productId: IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)]
        mockBackend.stubbedGetIntroEligibilityCompletionResult = (stubbedEligibility, nil)
        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == 1
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.eligible

        expect(self.mockBackend.invokedGetIntroEligibilityCount) == 1
    }

    func testSK1EligibilityIsNotFetchedFromBackendIfEligibilityAlreadyExists() throws {
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        let productId = "product_id"
        let stubbedEligibility = [productId: IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)]
        mockBackend.stubbedGetIntroEligibilityCompletionResult = (stubbedEligibility, nil)
        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == 1
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.eligible

        expect(self.mockBackend.invokedGetIntroEligibilityCount) == 0
    }

    func testSK1ErrorFetchingFromBackendAfterErrorCalculatingEligibility() throws {
        self.mockProductsManager.stubbedProductsCompletionResult = Set()
        let productId = "product_id"

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroDiscountEligibilityResult = ([:], stubbedError)

        mockBackend.stubbedGetIntroEligibilityCompletionResult = ([:], stubbedError)
        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckEligibility([productId]) { (receivedEligibilities) in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == 1
        expect(receivedEligibilities[productId]?.status) == IntroEligibilityStatus.unknown
    }

}
