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
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        mockSystemInfo = try MockSystemInfo(platformInfo: platformInfo,
                                            finishTransactions: true,
                                            storeKit2Setting: .enabledForCompatibleDevices)

        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        mockProductsManager = MockProductsManager(
            systemInfo: mockSystemInfo,
            requestTimeout: Configuration.storeKitRequestTimeoutDefault
        )
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                        receiptParser: MockReceiptParser())
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "app_user")

        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: mockSystemInfo,
            receiptFetcher: receiptFetcher,
            introEligibilityCalculator: mockIntroEligibilityCalculator,
            backend: mockBackend,
            currentUserProvider: currentUserProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: mockProductsManager
        )
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckEligibilityAsync() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let products = ["product_id",
                        "com.revenuecat.monthly_4.99.1_week_intro",
                        "com.revenuecat.annual_39.99.2_week_intro",
                        "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.eligible,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.eligible,
                        "lifetime": IntroEligibilityStatus.noIntroOfferExists]

        let eligibilities = try await XCTAsyncUnwrap(
            try await trialOrIntroPriceEligibilityChecker.sk2CheckEligibility(products)
        )
        expect(eligibilities.count) == expected.count

        for (product, receivedEligibility) in eligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityNoAsync() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let products = ["product_id",
                        "com.revenuecat.monthly_4.99.1_week_intro",
                        "com.revenuecat.annual_39.99.2_week_intro",
                        "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.eligible,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.eligible,
                        "lifetime": IntroEligibilityStatus.noIntroOfferExists]

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: products) { receivedEligibilities in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(expected.count))

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityNoAsyncWithFailure() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let products = ["product_id",
                        "com.revenuecat.monthly_4.99.1_week_intro",
                        "com.revenuecat.annual_39.99.2_week_intro",
                        "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.unknown,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.unknown,
                        "lifetime": IntroEligibilityStatus.unknown]

        mockProductsManager?.stubbedSk2StoreProductsThrowsError = true

        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: products) { receivedEligibilities in
            eligibilities = receivedEligibilities
        }

        expect(eligibilities).toEventuallyNot(beNil())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(expected.count))

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsEligibleForEligibleSubscription() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct()

        let status: IntroEligibilityStatus = try await withCheckedThrowingContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(status) == .eligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForLifetimeProductIsNoIntroOfferExists() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct("lifetime")

        let status: IntroEligibilityStatus = try await withCheckedThrowingContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(status) == .noIntroOfferExists
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsIneligibleAfterPurchasing() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let sk2Product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: sk2Product)

        let prePurchaseStatus: IntroEligibilityStatus = try await withCheckedThrowingContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(prePurchaseStatus) == .eligible

        _ = try await sk2Product.purchase()

        let postPurchaseStatus: IntroEligibilityStatus = try await withCheckedThrowingContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(postPurchaseStatus) == .ineligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForInvalidProductIsUnknown() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct()

        // We can't fetch an invalid StoreProduct to pass into the
        // eligibility checker so this just fakes an unknown response,
        // regardless of the real status from the checker
        let fakeStatus: IntroEligibilityStatus = try await withCheckedThrowingContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { _ in
                continuation.resume(returning: .unknown)
            }
        }

        expect(fakeStatus) == .unknown
    }
}
