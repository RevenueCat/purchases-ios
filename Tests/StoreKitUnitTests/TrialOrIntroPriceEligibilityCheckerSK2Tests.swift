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

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
// swiftlint:disable:next type_name
class TrialOrIntroPriceEligibilityCheckerSK2Tests: StoreKitConfigTestCase {

    var receiptFetcher: MockReceiptFetcher!
    var trialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var mockBackend: MockBackend!
    var mockProductsManager: MockProductsManager!
    var mockSystemInfo: MockSystemInfo!

    private var diagnosticsTracker: DiagnosticsTrackerType?

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var mockDiagnosticsTracker: MockDiagnosticsTracker {
        get throws {
            return try XCTUnwrap(self.diagnosticsTracker as? MockDiagnosticsTracker)
        }
    }

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)
    let mockDateProvider = MockDateProvider(stubbedNow: eventTimestamp1,
                                            subsequentNows: eventTimestamp2)

    override func setUpWithError() throws {
        try super.setUpWithError()
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "123")
        mockSystemInfo = MockSystemInfo(platformInfo: platformInfo,
                                        finishTransactions: true,
                                        storeKitVersion: .storeKit2)

        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: mockSystemInfo)
        mockProductsManager = MockProductsManager(
            diagnosticsTracker: nil,
            systemInfo: mockSystemInfo,
            requestTimeout: Configuration.storeKitRequestTimeoutDefault
        )
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                        receiptParser: MockReceiptParser())
        mockBackend = MockBackend()
        let mockOperationDispatcher = MockOperationDispatcher()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "app_user")

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.diagnosticsTracker = MockDiagnosticsTracker()
        } else {
            self.diagnosticsTracker = nil
        }

        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: mockSystemInfo,
            receiptFetcher: receiptFetcher,
            introEligibilityCalculator: mockIntroEligibilityCalculator,
            backend: mockBackend,
            currentUserProvider: currentUserProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: mockProductsManager,
            diagnosticsTracker: self.diagnosticsTracker,
            dateProvider: self.mockDateProvider
        )
    }

    @MainActor
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckEligibilityAsync() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let products: Set<String> = ["product_id",
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
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let products: Set<String> = ["product_id",
                                     "com.revenuecat.monthly_4.99.1_week_intro",
                                     "com.revenuecat.annual_39.99.2_week_intro",
                                     "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.eligible,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.eligible,
                        "lifetime": IntroEligibilityStatus.noIntroOfferExists]

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: products
            ) {
                completed($0)
            }
        }

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(expected.count))

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityNoAsyncWithFailure() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let products: Set<String> = ["product_id",
                                     "com.revenuecat.monthly_4.99.1_week_intro",
                                     "com.revenuecat.annual_39.99.2_week_intro",
                                     "lifetime"]
        let expected = ["product_id": IntroEligibilityStatus.unknown,
                        "com.revenuecat.monthly_4.99.1_week_intro": IntroEligibilityStatus.unknown,
                        "com.revenuecat.annual_39.99.2_week_intro": IntroEligibilityStatus.unknown,
                        "lifetime": IntroEligibilityStatus.unknown]

        self.mockProductsManager?.stubbedSk2StoreProductsResult = .failure(ErrorUtils.productRequestTimedOutError())

        let eligibilities = waitUntilValue { completed in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(
                productIdentifiers: products
            ) {
                completed($0)
            }
        }

        let receivedEligibilities = try XCTUnwrap(eligibilities)
        expect(receivedEligibilities).to(haveCount(expected.count))

        for (product, receivedEligibility) in receivedEligibilities {
            expect(receivedEligibility.status) == expected[product]
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsEligibleForEligibleSubscription() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct()

        let status: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(status) == .eligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForLifetimeProductIsNoIntroOfferExists() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct("lifetime")

        let status: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(status) == .noIntroOfferExists
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForProductIsIneligibleAfterPurchasing() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let sk2Product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: sk2Product)

        let prePurchaseStatus: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(prePurchaseStatus) == .eligible

        _ = try await sk2Product.purchase()

        let postPurchaseStatus: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(postPurchaseStatus) == .ineligible
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testCheckEligibilityForInvalidProductIsUnknown() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let storeProduct = try await self.fetchSk2StoreProduct()

        // We can't fetch an invalid StoreProduct to pass into the
        // eligibility checker so this just fakes an unknown response,
        // regardless of the real status from the checker
        let fakeStatus: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(product: storeProduct) { _ in
                continuation.resume(returning: .unknown)
            }
        }

        expect(fakeStatus) == .unknown
    }
}

// MARK: - Diagnostics

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension TrialOrIntroPriceEligibilityCheckerSK2Tests {

    func testSK2DoesNotTrackDiagnosticsWhenReceiptNotFetchedAndEmptyProductIds() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        waitUntil { completion in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: []) { _ in
                completion()
            }
        }

        expect(try self.mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value).to(beEmpty())
    }

    func testSK2TracksDiagnosticsWhenSK2ProductsSuccess() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let productIds = Set(["com.revenuecat.monthly_4.99.1_week_intro",
                              "com.revenuecat.annual_39.99.2_week_intro",
                              "lifetime"])

        let product1 = try await self.fetchSk2StoreProduct("com.revenuecat.monthly_4.99.1_week_intro")
        let product2 = try await self.fetchSk2StoreProduct("com.revenuecat.annual_39.99.2_week_intro")
        let product3 = try await self.fetchSk2StoreProduct("lifetime")
        self.mockProductsManager.stubbedSk2StoreProductsResult = .success([product1, product2, product3])
        self.mockSystemInfo.stubbedStorefront = MockStorefront(countryCode: "USA")

        await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: productIds) { _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try self.mockDiagnosticsTracker

        expect(mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value).to(haveCount(1))
        let params = mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value[0]

        expect(params.storeKitVersion) == .storeKit2
        expect(params.requestedProductIds) == productIds
        expect(params.eligibilityUnknownCount) == 0
        expect(params.eligibilityIneligibleCount) == 0
        expect(params.eligibilityEligibleCount) == 2
        expect(params.eligibilityNoIntroOfferCount) == 1
        expect(params.errorMessage).to(beNil())
        expect(params.errorCode).to(beNil())
        expect(params.storefront) == "USA"
        expect(params.responseTime) == Self.eventTimestamp2.timeIntervalSince(Self.eventTimestamp1)
    }

    func testSK2TracksDiagnosticsWhenSK2PartialProductsSuccess() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let productIds = Set(["com.revenuecat.monthly_4.99.1_week_intro",
                              "com.revenuecat.annual_39.99.2_week_intro",
                              "lifetime"])

        let product = try await self.fetchSk2StoreProduct("com.revenuecat.monthly_4.99.1_week_intro")
        self.mockProductsManager.stubbedSk2StoreProductsResult = .success([product])

        await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: productIds) { _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try self.mockDiagnosticsTracker

        expect(mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value).to(haveCount(1))
        let params = mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value[0]

        expect(params.storeKitVersion) == .storeKit2
        expect(params.requestedProductIds) == productIds
        expect(params.eligibilityUnknownCount) == 2
        expect(params.eligibilityIneligibleCount) == 0
        expect(params.eligibilityEligibleCount) == 1
        expect(params.eligibilityNoIntroOfferCount) == 0
        expect(params.errorMessage).to(beNil())
        expect(params.errorCode).to(beNil())
        expect(params.storefront).to(beNil())
        expect(params.responseTime) == Self.eventTimestamp2.timeIntervalSince(Self.eventTimestamp1)
    }

    func testSK2TracksDiagnosticsWhenSK2ProductsFailure() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let productIds = Set(["com.revenuecat.monthly_4.99.1_week_intro",
                              "com.revenuecat.annual_39.99.2_week_intro",
                              "lifetime"])

        let purchasesError = ErrorUtils.productRequestTimedOutError()
        self.mockProductsManager.stubbedSk2StoreProductsResult = .failure(purchasesError)

        await withCheckedContinuation { continuation in
            self.trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: productIds) { _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try self.mockDiagnosticsTracker

        expect(mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value).to(haveCount(1))
        let params = mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value[0]

        expect(params.storeKitVersion) == .storeKit2
        expect(params.requestedProductIds) == productIds
        expect(params.eligibilityUnknownCount) == 3
        expect(params.eligibilityIneligibleCount) == 0
        expect(params.eligibilityEligibleCount) == 0
        expect(params.eligibilityNoIntroOfferCount) == 0
        expect(params.errorMessage) == purchasesError.localizedDescription
        expect(params.errorCode) == purchasesError.errorCode
        expect(params.storefront).to(beNil())
        expect(params.responseTime) == Self.eventTimestamp2.timeIntervalSince(Self.eventTimestamp1)
    }
}
