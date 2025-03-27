//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerUIPreviewModeTests.swift
//
//  Created by Antonio Pallares on 20/2/25.

// swiftlint:disable type_name

import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class TrialOrIntroPriceEligibilityCheckerUIPreviewModeTests: StoreKitConfigTestCase {

    private var receiptFetcher: MockReceiptFetcher!
    private var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    private var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    private let mockBackend = MockBackend()
    private var mockOfferingsAPI: MockOfferingsAPI!
    private var mockProductsManager: MockProductsManager!
    private var mockSystemInfo: MockSystemInfo!

    private func setupUIPreviewMode(storeKitVersion: StoreKitVersion) throws {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        self.mockSystemInfo = MockSystemInfo(platformInfo: platformInfo,
                                             finishTransactions: true,
                                             uiPreviewMode: true,
                                             storeKitVersion: storeKitVersion)
        self.receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        self.mockProductsManager = MockProductsManager(diagnosticsTracker: nil,
                                                       systemInfo: mockSystemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                             receiptParser: MockReceiptParser())

        self.mockOfferingsAPI = try XCTUnwrap(self.mockBackend.offerings as? MockOfferingsAPI)
        let mockOperationDispatcher = MockOperationDispatcher()
        let userProvider = MockCurrentUserProvider(mockAppUserID: "app_user")
        self.trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: self.mockSystemInfo,
            receiptFetcher: self.receiptFetcher,
            introEligibilityCalculator: self.mockIntroEligibilityCalculator,
            backend: self.mockBackend,
            currentUserProvider: userProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: self.mockProductsManager,
            diagnosticsTracker: nil
        )
    }

    func testSK1CheckEligibilityInPreviewModeDoesNothing() throws {
        try setupUIPreviewMode(storeKitVersion: .storeKit1)

        let productIdentifiers: Set<String> = ["com.test.product1", "com.test.product2"]

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: productIdentifiers,
                completion: completed
            )
        }

        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.mockIntroEligibilityCalculator.invokedCheckTrialOrIntroDiscountEligibility) == false
        expect(self.mockOfferingsAPI.invokedGetIntroEligibility) == false
    }

    func testSK2CheckEligibilityInPreviewModeDoesNothing() throws {
        try setupUIPreviewMode(storeKitVersion: .storeKit2)

        let productIdentifiers: Set<String> = ["com.test.product1", "com.test.product2"]

        // Verify early return with empty dictionary
        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: productIdentifiers,
                completion: completed
            )
        }

        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.mockIntroEligibilityCalculator.invokedCheckTrialOrIntroDiscountEligibility) == false
        expect(self.mockProductsManager.invokedSk2StoreProducts) == false
        expect(self.mockOfferingsAPI.invokedGetIntroEligibility) == false
    }
}
