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
@_spi(Internal) @testable import RevenueCat
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
    private var mockOperationDispatcher: MockOperationDispatcher!

    private var groupEligibilityCache: SubscriptionGroupEligibilityCache!
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

    override func setUp() async throws {
        try await super.setUp()

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // StoreKitTest can keep stale intro eligibility for several seconds after clearTransactions()
            // (FB24137836). Wait for the fixture to reset before testing the SDK's eligibility handling.
            let products = try await StoreKit.Product.products(for: [
                "com.revenuecat.monthly_4.99.1_week_intro",
                "com.revenuecat.annual_39.99.2_week_intro"
            ])
            expect(products).to(haveCount(2))
            for product in products {
                let subscription = try XCTUnwrap(product.subscription)
                try await asyncWait(description: "Intro eligibility did not reset for \(product.id)",
                                    timeout: .seconds(30)) {
                    await SK2Product.SubscriptionInfo.isEligibleForIntroOffer(for: subscription.subscriptionGroupID)
                }
            }
        }
    }

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
        mockProductsManager.fetchProductsFromStoreKit = true
        mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                        receiptParser: MockReceiptParser())
        mockBackend = MockBackend()
        self.mockOperationDispatcher = MockOperationDispatcher()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "app_user")

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.diagnosticsTracker = MockDiagnosticsTracker()
        } else {
            self.diagnosticsTracker = nil
        }

        self.groupEligibilityCache = .init()
        trialOrIntroPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: mockSystemInfo,
            receiptFetcher: receiptFetcher,
            introEligibilityCalculator: mockIntroEligibilityCalculator,
            backend: mockBackend,
            currentUserProvider: currentUserProvider,
            operationDispatcher: mockOperationDispatcher,
            productsManager: mockProductsManager,
            diagnosticsTracker: self.diagnosticsTracker,
            groupEligibilityCache: self.groupEligibilityCache,
            dateProvider: self.mockDateProvider
        )
    }

    @MainActor
    func testAsyncProductRequestEscalatesStoreKitGroupTask() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let checker = self.makePriorityRecordingChecker()
        let check = checker.check
        defer { check.release() }
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let warmup = Task.detached(priority: .background) {
            await caching.checkEligibility(productIdentifiers: [monthly.id])
        }
        try await asyncWait { check.initialPriority.value != nil }
        expect(check.initialPriority.value) == .background

        let paywall = Task.detached(priority: .userInitiated) {
            await caching.checkEligibility(productIdentifiers: [monthly.id])
        }
        try await asyncWait { check.currentPriority.value == .userInitiated }
        self.logger.verifyMessageWasLogged("Waiting for an in-flight intro eligibility", expectedCount: 1)
        expect(check.invocations.value) == 1
        check.release()
        let warmupResult = await warmup.value
        let paywallResult = await paywall.value
        expect(warmupResult[monthly.id]?.status) == .eligible
        expect(paywallResult) == warmupResult
    }

    @MainActor
    func testDisjointProductRequestEscalatesExistingSubscriptionGroupTask() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let groupID = try XCTUnwrap(monthly.subscriptionGroupIdentifier)
        expect(annual.subscriptionGroupIdentifier) == groupID
        let checker = self.makePriorityRecordingChecker()
        let check = checker.check
        defer { check.release() }
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])

        let warmup = Task.detached(priority: .background) {
            await caching.checkEligibility(productIdentifiers: [monthly.id])
        }
        try await asyncWait { check.initialPriority.value != nil }
        expect(check.initialPriority.value) == .background

        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let paywall = Task.detached(priority: .userInitiated) {
            await caching.checkEligibility(productIdentifiers: [annual.id])
        }
        // Awaiting the handles here would donate the test's priority and could hide a broken join path.
        try await asyncWait { check.currentPriority.value == .userInitiated }
        self.logger.verifyMessageWasLogged(
            "reusing in-flight check for subscription group '\(groupID)'", expectedCount: 1
        )
        self.logger.verifyMessageWasNotLogged("Waiting for an in-flight intro eligibility")
        expect(check.invocations.value) == 1
        expect(self.mockProductsManager.invokedProductsParametersList) == [[monthly.id], [annual.id]]

        check.release()
        let warmupResult = await warmup.value
        let paywallResult = await paywall.value
        expect(warmupResult) == [monthly.id: IntroEligibility(eligibilityStatus: .eligible)]
        expect(paywallResult) == [annual.id: IntroEligibility(eligibilityStatus: .eligible)]
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
        self.logger.verifyMessageWasLogged("starting product lookup", level: .debug, expectedCount: 1)
        // Both subscriptions share a group, so StoreKit is checked once.
        self.logger.verifyMessageWasLogged("eligible=true", level: .debug, expectedCount: 1)
        self.logger.verifyMessageWasLogged("check finished in", level: .debug, expectedCount: 1)
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

    @MainActor
    @available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
    func testDeliveryTimingIncludesFirstMainActorDispatchDelay() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let clock = try XCTUnwrap(self.mockSystemInfo.clock as? TestClock)
        self.mockOperationDispatcher.shouldHoldDispatchOnMainActorBlocks = true
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])
        var receivedResult: [String: IntroEligibility]?

        self.trialOrIntroPriceEligibilityChecker.checkEligibility(productIdentifiers: ["missing"]) {
            expect(Thread.isMainThread).to(beTrue())
            receivedResult = $0
        }

        let heldBlocks = self.mockOperationDispatcher.heldMainActorBlocks
        try await asyncWait { heldBlocks.value.count == 1 }
        expect(receivedResult).to(beNil())
        self.logger.verifyMessageWasNotLogged("Delivering intro eligibility results")
        clock.advance(by: .seconds(7))
        clock.now = .distantPast
        self.mockOperationDispatcher.performHeldMainActorBlocks()

        expect(receivedResult?["missing"]?.status) == .unknown
        expect(self.mockOperationDispatcher.pendingMainActorDispatches.value) == 0
        self.logger.verifyMessageWasLogged(
            "Delivering intro eligibility results after 7.0s waiting for the main queue.",
            level: .debug, expectedCount: 1
        )
    }

    @MainActor
    func testCachingWrapperDeliveryTimingExcludesProductLookup() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let clock = try XCTUnwrap(self.mockSystemInfo.clock as? TestClock)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        self.mockOperationDispatcher.shouldHoldDispatchOnMainActorBlocks = true
        self.mockProductsManager.stubbedProductsCompletionResult = .success([])
        self.mockProductsManager.shouldDeferProductsCompletion = true
        var productLookupCompleted = false
        defer {
            if !productLookupCompleted, self.mockProductsManager.deferredProductsRequestCount == 1 {
                self.mockProductsManager.completeDeferredProductsRequest(at: 0)
            }
            self.mockOperationDispatcher.performHeldMainActorBlocks()
        }
        var receivedResult: [String: IntroEligibility]?

        caching.checkEligibility(productIdentifiers: ["missing"]) {
            expect(Thread.isMainThread).to(beTrue())
            receivedResult = $0
        }
        try await asyncWait { self.mockProductsManager.deferredProductsRequestCount == 1 }
        clock.advance(by: .seconds(5))
        productLookupCompleted = true
        self.mockProductsManager.completeDeferredProductsRequest(at: 0)

        let heldBlocks = self.mockOperationDispatcher.heldMainActorBlocks
        try await asyncWait(description: "Caching wrapper did not schedule callback delivery") {
            heldBlocks.value.count == 1
        }
        expect(receivedResult).to(beNil())
        self.logger.verifyMessageWasNotLogged("Delivering intro eligibility results")
        clock.advance(by: .seconds(7))
        clock.now = .distantPast
        self.mockOperationDispatcher.performHeldMainActorBlocks()

        expect(receivedResult?["missing"]?.status) == .unknown
        expect(self.mockOperationDispatcher.pendingMainActorDispatches.value) == 0
        self.logger.verifyMessageWasLogged("Delivering intro eligibility results", expectedCount: 1)
        self.logger.verifyMessageWasLogged(
            "Delivering intro eligibility results after 7.0s waiting for the main queue.",
            level: .debug, expectedCount: 1
        )
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

        self.mockProductsManager?.stubbedProductsCompletionResult = .failure(ErrorUtils.productRequestTimedOutError())

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
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)

        let prePurchaseStatus: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: storeProduct) { status in
                continuation.resume(returning: status)
            }
        }

        expect(prePurchaseStatus) == .eligible

        _ = try await sk2Product.purchase()

        // StoreKitTest can update eligibility after purchase() returns. Wait for that state change
        // before testing the SDK's cache invalidation, rather than relying on a fixed delay.
        let groupID = try XCTUnwrap(sk2Product.subscription?.subscriptionGroupID)
        try await asyncWait(description: "StoreKit intro eligibility did not update after purchase",
                            timeout: .seconds(10)) {
            await !SK2Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupID)
        }

        // Purchases invalidates eligibility when it receives updated CustomerInfo after a purchase.
        // This test uses the checker directly, so perform that invalidation explicitly.
        caching.clearCache()

        let postPurchaseStatus: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: storeProduct) { status in
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

// MARK: - Subscription group caching

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension TrialOrIntroPriceEligibilityCheckerSK2Tests {

    @MainActor
    func testCachingWrapperReusesGroupResultThroughItsNormalEntryPoint() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )

        for product in [monthly, annual, monthly] {
            let status: IntroEligibilityStatus = await withCheckedContinuation { continuation in
                caching.checkEligibility(product: product) { continuation.resume(returning: $0) }
            }
            expect(status) == .eligible
        }

        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 1)
        self.logger.verifyMessageWasLogged("reusing cached result", expectedCount: 1)
    }

    @MainActor
    func testCachedProductEligibilitySurvivesProductLookupFailure() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let first: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: monthly) { continuation.resume(returning: $0) }
        }
        expect(first) == .eligible

        self.mockProductsManager.stubbedProductsCompletionResult = .failure(ErrorUtils.productRequestTimedOutError())
        let failed: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: monthly) { continuation.resume(returning: $0) }
        }
        expect(failed) == .eligible
        expect(self.mockProductsManager.invokedProductsCount) == 1

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let retried: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: monthly) { continuation.resume(returning: $0) }
        }
        expect(retried) == .eligible
        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 1)
    }

    @MainActor
    func testCachedSK2ProductCompletesSynchronouslyOnCallersThread() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let primed: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: monthly) { continuation.resume(returning: $0) }
        }
        expect(primed) == .eligible

        let finished = self.expectation(description: "Background cache lookup finished")
        DispatchQueue(label: "eligibility-cache-caller").async {
            let returned = Atomic(false)
            let received = Atomic<IntroEligibilityStatus?>(nil)
            caching.checkEligibility(product: monthly) { status in
                expect(Thread.isMainThread) == false
                expect(returned.value) == false
                received.value = status
            }
            returned.value = true
            expect(received.value) == .eligible
            finished.fulfill()
        }
        await self.fulfillment(of: [finished], timeout: 1)
    }

    @MainActor
    func testSK2CachedGroupForAnotherProductDoesNotTrackDiagnostics() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        for product in [monthly, annual, monthly] {
            let status: IntroEligibilityStatus = await withCheckedContinuation { continuation in
                caching.checkEligibility(product: product) { continuation.resume(returning: $0) }
            }
            expect(status) == .eligible
        }

        let tracked = try self.mockDiagnosticsTracker.trackedAppleTrialOrIntroEligibilityRequestParams.value
        expect(tracked).to(haveCount(1))
        expect(tracked.first?.requestedProductIds) == [monthly.id]
        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 1)
        self.logger.verifyMessageWasLogged("reusing cached result", expectedCount: 1)
    }

    @MainActor
    func testProductLookupFailureForNewProductRetainsCachedGroupAnswer() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: self.trialOrIntroPriceEligibilityChecker)
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let first: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: monthly) { continuation.resume(returning: $0) }
        }
        expect(first) == .eligible

        self.mockProductsManager.stubbedProductsCompletionResult = .failure(ErrorUtils.productRequestTimedOutError())
        let failed: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: annual) { continuation.resume(returning: $0) }
        }
        expect(failed) == .unknown

        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let retried: IntroEligibilityStatus = await withCheckedContinuation { continuation in
            caching.checkEligibility(product: annual) { continuation.resume(returning: $0) }
        }
        expect(retried) == .eligible
        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 1)
    }

    @MainActor
    func testDisjointProductRequestsReuseGroupResultButStillRequireAnIntroOffer() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let noIntro = StoreProduct(sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99_no_trial"))
        let calls = Atomic<[String]>([])
        let check: @Sendable (String) async -> Bool = { groupID in
            calls.modify { $0.append(groupID) }
            return true
        }

        for product in [monthly, annual, noIntro] {
            self.mockProductsManager.stubbedProductsCompletionResult = .success([product])
            let result = try await self.trialOrIntroPriceEligibilityChecker.sk2CheckEligibility(
                [product.id], checkSubscriptionGroup: check
            )
            let expected: IntroEligibilityStatus = product == noIntro ? .noIntroOfferExists : .eligible
            expect(result[product.id]?.status) == expected
        }

        expect(calls.value) == [try XCTUnwrap(monthly.subscriptionGroupIdentifier)]
        self.logger.verifyMessageWasLogged("reusing cached result", expectedCount: 1)
    }

    @MainActor
    func testInvalidationDuringGroupCheckStartsFreshCheckAndCachesOnlyItsResult() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let checker = try XCTUnwrap(self.trialOrIntroPriceEligibilityChecker)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let oldRequest = Task {
            try await checker.sk2CheckEligibility(
                [monthly.id], checkSubscriptionGroup: check.call
            )
        }
        try await asyncWait { check.invocations.count == 1 }

        caching.clearCache()
        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let newRequest = Task {
            try await checker.sk2CheckEligibility(
                [annual.id], checkSubscriptionGroup: check.call
            )
        }
        try await asyncWait { check.invocations.count == 2 }

        check.complete(at: 1, eligible: false)
        let newResult = try await newRequest.value
        check.complete(at: 0, eligible: true)
        let oldResult = try await oldRequest.value

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let cachedResult = try await checker.sk2CheckEligibility(
            [monthly.id], checkSubscriptionGroup: check.call
        )
        expect(oldResult[monthly.id]?.status) == .eligible
        expect(newResult[annual.id]?.status) == .ineligible
        expect(cachedResult[monthly.id]?.status) == .ineligible
        expect(check.invocations.count) == 2
    }

    @MainActor
    func testProductLookupFinishingAfterInvalidationReusesNewGroupResult() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let checker = try XCTUnwrap(self.trialOrIntroPriceEligibilityChecker)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let calls = Atomic(0)
        let check: @Sendable (String) async -> Bool = { _ in
            // A duplicate check would return a different result and replace the cached answer.
            calls.modify {
                $0 += 1
                return $0 > 1
            }
        }

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        self.mockProductsManager.shouldDeferProductsCompletion = true
        let oldRequest = Task {
            try await checker.sk2CheckEligibility(
                [monthly.id], checkSubscriptionGroup: check
            )
        }
        var needsCompletion = true
        defer {
            if needsCompletion, self.mockProductsManager.deferredProductsRequestCount == 1 {
                self.mockProductsManager.completeDeferredProductsRequest(at: 0)
            }
        }
        try await asyncWait { self.mockProductsManager.deferredProductsRequestCount == 1 }

        caching.clearCache()
        self.mockProductsManager.shouldDeferProductsCompletion = false
        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let newResult = try await checker.sk2CheckEligibility(
            [annual.id], checkSubscriptionGroup: check
        )

        needsCompletion = false
        self.mockProductsManager.completeDeferredProductsRequest(at: 0)
        let oldResult = try await oldRequest.value
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let cachedResult = try await checker.sk2CheckEligibility(
            [monthly.id], checkSubscriptionGroup: check
        )

        expect(oldResult[monthly.id]?.status) == .ineligible
        expect(newResult[annual.id]?.status) == .ineligible
        expect(cachedResult[monthly.id]?.status) == .ineligible
        expect(calls.value) == 1
    }

    @MainActor
    func testConcurrentDisjointProductRequestsShareSubscriptionGroupCheck() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let checker = try XCTUnwrap(self.trialOrIntroPriceEligibilityChecker)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let monthlyRequest = Task {
            try await checker.sk2CheckEligibility(
                [monthly.id], checkSubscriptionGroup: check.call
            )
        }
        try await asyncWait { check.invocations.count == 1 }

        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let annualRequest = Task {
            try await checker.sk2CheckEligibility(
                [annual.id], checkSubscriptionGroup: check.call
            )
        }
        try await asyncWait {
            self.logger.messages.contains { $0.message.contains("reusing in-flight check") }
        }
        check.complete(at: 0, eligible: true)

        let monthlyResult = try await monthlyRequest.value
        let annualResult = try await annualRequest.value
        expect(Set(monthlyResult.keys)) == [monthly.id]
        expect(Set(annualResult.keys)) == [annual.id]
        expect(monthlyResult[monthly.id]?.status) == .eligible
        expect(annualResult[annual.id]?.status) == .eligible
        expect(check.invocations.count) == 1
    }

    @MainActor
    func testInvalidationAllowsIneligibleGroupToBecomeEligible() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let monthly = StoreProduct(sk2Product: try await self.fetchSk2Product())
        let annual = StoreProduct(
            sk2Product: try await self.fetchSk2Product("com.revenuecat.annual_39.99.2_week_intro")
        )
        let checker = try XCTUnwrap(self.trialOrIntroPriceEligibilityChecker)
        let caching = CachingTrialOrIntroPriceEligibilityChecker(checker: checker)
        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let before = try await checker.sk2CheckEligibility(
            [monthly.id], checkSubscriptionGroup: { _ in false }
        )

        caching.clearCache()
        self.mockProductsManager.stubbedProductsCompletionResult = .success([annual])
        let after = try await checker.sk2CheckEligibility(
            [annual.id], checkSubscriptionGroup: { _ in true }
        )

        self.mockProductsManager.stubbedProductsCompletionResult = .success([monthly])
        let cached = try await checker.sk2CheckEligibility(
            [monthly.id], checkSubscriptionGroup: { _ in
                XCTFail("Expected the new group result to be cached")
                return false
            }
        )
        expect(before[monthly.id]?.status) == .ineligible
        expect(after[annual.id]?.status) == .eligible
        expect(cached[monthly.id]?.status) == .eligible
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
        self.mockProductsManager.stubbedProductsCompletionResult = .success(
            Set([product1, product2, product3].map(StoreProduct.from(product:)))
        )
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
        self.mockProductsManager.stubbedProductsCompletionResult = .success([StoreProduct.from(product: product)])

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
        self.mockProductsManager.stubbedProductsCompletionResult = .failure(purchasesError)

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

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
private extension TrialOrIntroPriceEligibilityCheckerSK2Tests {

    func makePriorityRecordingChecker() -> PriorityRecordingSK2EligibilityChecker {
        return PriorityRecordingSK2EligibilityChecker(
            systemInfo: self.mockSystemInfo, receiptFetcher: self.receiptFetcher,
            introEligibilityCalculator: self.mockIntroEligibilityCalculator, backend: self.mockBackend,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: "app_user"),
            operationDispatcher: self.mockOperationDispatcher, productsManager: self.mockProductsManager,
            diagnosticsTracker: self.diagnosticsTracker, groupEligibilityCache: self.groupEligibilityCache
        )
    }

}

private final class PriorityRecordingSK2EligibilityChecker: TrialOrIntroPriceEligibilityChecker, @unchecked Sendable {

    let check = PriorityRecordingGroupCheck()

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2CheckEligibility(
        _ productIdentifiers: Set<String>,
        checkSubscriptionGroup: @escaping @Sendable (String) async -> Bool
    ) async throws -> [String: IntroEligibility] {
        return try await super.sk2CheckEligibility(productIdentifiers, checkSubscriptionGroup: self.check.call)
    }

}
