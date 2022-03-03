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

    typealias ContinuationStatusResult = CheckedContinuation<IntroEligibilityStatus, Error>

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
                                            finishTransactions: true)

        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        mockProductsManager = MockProductsManager(systemInfo: mockSystemInfo)
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

        let eligibilities = try await trialOrIntroPriceEligibilityChecker.sk2CheckEligibility(products)
        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == expected.count

        for (product, receivedEligibility) in receivedEligibilities {
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

        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.checkEligibility(productIdentifiers: products) { receivedEligibilities in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == expected.count

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

        var completionCalled = false
        var eligibilities: [String: IntroEligibility]?
        trialOrIntroPriceEligibilityChecker!.checkEligibility(productIdentifiers: products) { receivedEligibilities in
            completionCalled = true
            eligibilities = receivedEligibilities
        }

        expect(completionCalled).toEventually(beTrue())

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities.count) == expected.count

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsEligible() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro"
        ])

        let sk2Product = try await ProductsFetcherSK2().products(identifiers: productIdentifiers).first
        let receivedProduct = try XCTUnwrap(sk2Product)
        let storeProduct = StoreProduct.from(product: receivedProduct)

        var completionCalled = false

        let status = try await withCheckedThrowingContinuation({ (continuation: ContinuationStatusResult) in
            self.trialOrIntroPriceEligibilityChecker!.checkEligibility(product: storeProduct) { status in
                completionCalled = true
                continuation.resume(returning: status)
            }
        })

        expect(completionCalled) == true
        expect(status) == .eligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForLifetimeProductIsNoIntroOfferExists() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "lifetime"
        ])

        let sk2Product = try await ProductsFetcherSK2().products(identifiers: productIdentifiers).first
        let receivedProduct = try XCTUnwrap(sk2Product)
        let storeProduct = StoreProduct.from(product: receivedProduct)

        var completionCalled = false

        let status = try await withCheckedThrowingContinuation({ (continuation: ContinuationStatusResult) in
            self.trialOrIntroPriceEligibilityChecker!.checkEligibility(product: storeProduct) { status in
                completionCalled = true
                continuation.resume(returning: status)
            }
        })

        expect(completionCalled) == true
        expect(status) == .noIntroOfferExists
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsIneligibleAfterPurchasing() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro"
        ])

        let sk2Product = try await ProductsFetcherSK2().products(identifiers: productIdentifiers).first
        let receivedProduct = try XCTUnwrap(sk2Product)
        let storeProduct = StoreProduct.from(product: receivedProduct)

        var completionCalled = false

        let prePurchaseStatus = try await withCheckedThrowingContinuation({ (continuation: ContinuationStatusResult) in
            self.trialOrIntroPriceEligibilityChecker!.checkEligibility(product: storeProduct) { status in
                completionCalled = true
                continuation.resume(returning: status)
            }
        })

        expect(completionCalled) == true
        expect(prePurchaseStatus) == .eligible

        let purchasableSK2Product = try XCTUnwrap(storeProduct.sk2Product)
        _ = try await purchasableSK2Product.purchase()

        completionCalled = false

        let postPurchaseStatus = try await withCheckedThrowingContinuation({ (continuation: ContinuationStatusResult) in
            self.trialOrIntroPriceEligibilityChecker!.checkEligibility(product: storeProduct) { status in
                completionCalled = true
                continuation.resume(returning: status)
            }
        })

        expect(completionCalled) == true
        expect(postPurchaseStatus) == .ineligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsUnknown() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let productIdentifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro"
        ])

        let sk2Product = try await ProductsFetcherSK2().products(identifiers: productIdentifiers).first
        let receivedProduct = try XCTUnwrap(sk2Product)
        let storeProduct = StoreProduct.from(product: receivedProduct)

        var completionCalled = false

        // We can't fetch an invalid StoreProduct to pass into the
        // eligibility checker so this just fakes an unknown response,
        // regardless of the real status from the checker
        let fakeStatus = try await withCheckedThrowingContinuation({ (continuation: ContinuationStatusResult) in
            self.trialOrIntroPriceEligibilityChecker!.checkEligibility(product: storeProduct) { _ in
                completionCalled = true
                continuation.resume(returning: .unknown)
            }
        })

        expect(completionCalled) == true
        expect(fakeStatus) == .unknown
    }
}
