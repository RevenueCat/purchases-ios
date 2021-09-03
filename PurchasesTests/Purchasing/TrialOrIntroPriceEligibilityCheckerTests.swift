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
import XCTest
@testable import RevenueCat

class TrialOrIntroPriceEligibilityCheckerTests: XCTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!

    func setup() {
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher())
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let identityManager = MockIdentityManager(mockAppUserID: "app_user")

        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                                                                  introEligibilityCalculator: mockIntroEligibilityCalculator,
                                                                                  backend: mockBackend,
                                                                                  identityManager: identityManager,
                                                                                  operationDispatcher: mockOperationDispatcher)
    }

    func testGetEligibility() {
        setup()
        trialOrIntroPriceEligibilityChecker!.sk1checkTrialOrIntroPriceEligibility([]) { (eligibilities) in
        }
    }

    func testGetEligibilityFetchesAReceipt() {
        setup()
        trialOrIntroPriceEligibilityChecker!.sk1checkTrialOrIntroPriceEligibility([]) { (eligibilities) in
        }

        expect(self.receiptFetcher.receiptDataCalled).to(beTrue())
    }

    func testSK1EligibilityIsCalculatedFromReceiptData() throws {
        setup()
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult = (["product_id": IntroEligibilityStatus.eligible], nil)

        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1checkTrialOrIntroPriceEligibility([]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 1
    }

    func testSK1EligibilityIsFetchedFromBackendIfErrorCalculatingEligibility() throws {
        setup()
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult = ([:], stubbedError)

        mockBackend.stubbedGetIntroEligibilityCompletionResult = (["product_id": IntroEligibility(eligibilityStatus: IntroEligibilityStatus.eligible)], nil)
        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1checkTrialOrIntroPriceEligibility([]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 1
    }

    func testSK1ErrorFetchingFromBackendAfterErrorCalculatingEligibility() throws {
        setup()
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult = ([:], stubbedError)

        mockBackend.stubbedGetIntroEligibilityCompletionResult = ([:], stubbedError)
        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1checkTrialOrIntroPriceEligibility([]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 0
    }
    
}
