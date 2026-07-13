//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroPriceEligibilityCheckerSimulatedStoreTests.swift
//
//  Created by Toni Rico.

// swiftlint:disable type_name

import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class TrialOrIntroPriceEligibilityCheckerSimulatedStoreTests: StoreKitConfigTestCase {

    private var receiptFetcher: MockReceiptFetcher!
    private var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    private var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    private let mockBackend = MockBackend()
    private var mockOfferingsAPI: MockOfferingsAPI!
    private var mockProductsManager: MockProductsManager!
    private var mockSystemInfo: MockSystemInfo!

    private static let productWithFreeTrialID = "com.test.product_with_free_trial"
    private static let productWithIntroPriceID = "com.test.product_with_intro_price"
    private static let productWithoutDiscountID = "com.test.product_without_discount"

    private func setupSimulatedStore(storeKitVersion: StoreKitVersion) throws {
        self.mockSystemInfo = MockSystemInfo(finishTransactions: true,
                                             storeKitVersion: storeKitVersion)
        self.mockSystemInfo.stubbedApiKeyValidationResult = .simulatedStore

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

    private func stubProducts() {
        let freeTrialDiscount = TestStoreProductDiscount(
            identifier: "$rc_free_trial",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 7, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
        let introPriceDiscount = TestStoreProductDiscount(
            identifier: "$rc_intro_price",
            price: 1.99,
            localizedPriceString: "$1.99",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: .init(value: 1, unit: .month),
            numberOfPeriods: 3,
            type: .introductory
        )

        let productWithFreeTrial = TestStoreProduct(
            localizedTitle: "Product With Free Trial",
            price: 99.99,
            currencyCode: "USD",
            localizedPriceString: "$99.99",
            productIdentifier: Self.productWithFreeTrialID,
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryDiscount: freeTrialDiscount,
            locale: .current
        )
        let productWithIntroPrice = TestStoreProduct(
            localizedTitle: "Product With Intro Price",
            price: 99.99,
            currencyCode: "USD",
            localizedPriceString: "$99.99",
            productIdentifier: Self.productWithIntroPriceID,
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryDiscount: introPriceDiscount,
            locale: .current
        )
        let productWithoutDiscount = TestStoreProduct(
            localizedTitle: "Product Without Discount",
            price: 99.99,
            currencyCode: "USD",
            localizedPriceString: "$99.99",
            productIdentifier: Self.productWithoutDiscountID,
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionPeriod: .init(value: 1, unit: .year),
            locale: .current
        )

        self.mockProductsManager.stubbedProductsCompletionResult = .success([
            productWithFreeTrial.toStoreProduct(),
            productWithIntroPrice.toStoreProduct(),
            productWithoutDiscount.toStoreProduct()
        ])
    }

    func testSimulatedStoreReportsEligibleForProductsWithIntroductoryDiscount() throws {
        try setupSimulatedStore(storeKitVersion: .storeKit2)
        stubProducts()

        let productIdentifiers: Set<String> = [
            Self.productWithFreeTrialID,
            Self.productWithIntroPriceID,
            Self.productWithoutDiscountID
        ]

        let eligibilities = try XCTUnwrap(waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: productIdentifiers,
                completion: completed
            )
        })

        expect(eligibilities[Self.productWithFreeTrialID]?.status) == .eligible
        expect(eligibilities[Self.productWithIntroPriceID]?.status) == .eligible
        expect(eligibilities[Self.productWithoutDiscountID]?.status) == .noIntroOfferExists

        // The backend computes eligibility for the Simulated Store, so we never report ineligible.
        expect(eligibilities.values.map(\.status)).toNot(contain(IntroEligibilityStatus.ineligible))
    }

    func testSimulatedStoreReportsUnknownForUnknownProducts() throws {
        try setupSimulatedStore(storeKitVersion: .storeKit2)
        stubProducts()

        let unknownProductID = "com.test.not_returned_by_manager"
        let productIdentifiers: Set<String> = [Self.productWithFreeTrialID, unknownProductID]

        let eligibilities = try XCTUnwrap(waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: productIdentifiers,
                completion: completed
            )
        })

        expect(eligibilities[Self.productWithFreeTrialID]?.status) == .eligible
        expect(eligibilities[unknownProductID]?.status) == .unknown
    }

    func testSimulatedStoreDoesNotCheckEligibilityThroughStoreKitOrBackend() throws {
        try setupSimulatedStore(storeKitVersion: .storeKit2)
        stubProducts()

        let productIdentifiers: Set<String> = [Self.productWithFreeTrialID]

        _ = waitUntilValue { completed in
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
