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
            diagnosticsTracker: nil,
            groupEligibilityCache: .init()
        )
    }

    func testSK1CheckEligibilityInPreviewModeDoesNothing() async throws {
        try setupUIPreviewMode(storeKitVersion: .storeKit1)

        let productIdentifiers: Set<String> = ["com.test.product1", "com.test.product2"]

        let eligibilities = await self.trialOrIntroPriceEligibilityChecker.checkEligibility(
            productIdentifiers: productIdentifiers
        )

        expect(Set(eligibilities.keys)) == productIdentifiers
        expect(eligibilities.values.map(\.status)).to(allPass(equal(IntroEligibilityStatus.unknown)))

        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.mockIntroEligibilityCalculator.invokedCheckTrialOrIntroDiscountEligibility) == false
        expect(self.mockOfferingsAPI.invokedGetIntroEligibility) == false
    }

    func testSK2CheckEligibilityInPreviewModeDoesNothing() async throws {
        try setupUIPreviewMode(storeKitVersion: .storeKit2)

        let productIdentifiers: Set<String> = ["com.test.product1", "com.test.product2"]

        let eligibilities = await self.trialOrIntroPriceEligibilityChecker.checkEligibility(
            productIdentifiers: productIdentifiers
        )

        expect(Set(eligibilities.keys)) == productIdentifiers
        expect(eligibilities.values.map(\.status)).to(allPass(equal(IntroEligibilityStatus.unknown)))

        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.mockIntroEligibilityCalculator.invokedCheckTrialOrIntroDiscountEligibility) == false
        expect(self.mockOfferingsAPI.invokedGetIntroEligibility) == false
    }

    func testCachingWrapperInSK2PreviewModeSkipsProductAndGroupLookups() async throws {
        try self.setupUIPreviewMode(storeKitVersion: .storeKit2)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        for _ in 0..<2 {
            let result = await withCheckedContinuation { continuation in
                caching.checkEligibility(productIdentifiers: ["product_id"]) { continuation.resume(returning: $0) }
            }
            expect(result["product_id"]?.status) == .unknown
        }
        expect(self.mockProductsManager.invokedProductsCount) == 0
        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.mockIntroEligibilityCalculator.invokedCheckTrialOrIntroDiscountEligibility) == false
        expect(self.mockOfferingsAPI.invokedGetIntroEligibility) == false
        self.logger.verifyMessageWasNotLogged("starting StoreKit check")
    }
}
