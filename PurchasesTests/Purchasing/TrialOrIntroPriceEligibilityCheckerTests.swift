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
import StoreKit

class TrialOrIntroPriceEligibilityCheckerTests: XCTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!
    var mockProductsManager: MockProductsManager!

    func setup() {
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher())
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let identityManager = MockIdentityManager(mockAppUserID: "app_user")
        let mockProductsManager = MockProductsManager()
        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(receiptFetcher: receiptFetcher,
                                                                                  introEligibilityCalculator: mockIntroEligibilityCalculator,
                                                                                  backend: mockBackend,
                                                                                  identityManager: identityManager,
                                                                                  operationDispatcher: mockOperationDispatcher,
                                                                                  productsManager: mockProductsManager)
    }

    func testSK1CheckTrialOrIntroPriceEligibility() {
        setup()
        trialOrIntroPriceEligibilityChecker!.sk1CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
        }
    }

    func testSK1CheckTrialOrIntroPriceEligibilityFetchesAReceipt() {
        setup()
        trialOrIntroPriceEligibilityChecker!.sk1CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
        }

        expect(self.receiptFetcher.receiptDataCalled).to(beTrue())
    }

    func testSK1EligibilityIsCalculatedFromReceiptData() throws {
        setup()
        mockIntroEligibilityCalculator.stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult = (["product_id": IntroEligibilityStatus.eligible], nil)

        var completionCalled = false
        var maybeEligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.sk1CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
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
        trialOrIntroPriceEligibilityChecker!.sk1CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
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
        trialOrIntroPriceEligibilityChecker!.sk1CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
            completionCalled = true
            maybeEligibilities = eligibilities
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedEligibilities = try XCTUnwrap(maybeEligibilities)
        expect(receivedEligibilities.count) == 0
    }

    func testSK2CheckTrialOrIntroPriceEligibility() {
        setup()
        // todo: finish when fetching products works
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            trialOrIntroPriceEligibilityChecker!.sk2CheckTrialOrIntroPriceEligibility([]) { (eligibilities) in
            }
        }
    }

}
