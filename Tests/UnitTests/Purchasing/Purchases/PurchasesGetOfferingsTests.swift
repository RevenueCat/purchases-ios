//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesGetOfferingsTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

private final class HeldEligibilityChecker: TrialOrIntroPriceEligibilityCheckerType {

    let requests: Atomic<[Set<String>]> = .init([])
    private let completions: Atomic<[ReceiveIntroEligibilityBlock]> = .init([])

    func checkEligibility(productIdentifiers: Set<String>, completion: @escaping ReceiveIntroEligibilityBlock) {
        self.completions.modify { $0.append(completion) }
        self.requests.modify { $0.append(productIdentifiers) }
    }

    func completeNext() {
        let completion = self.completions.modify { $0.isEmpty ? nil : $0.removeFirst() }
        completion?([:])
    }

}

class PurchasesGetOfferingsTests: BasePurchasesTests {

    func testFirstInitializationGetsOfferingsIfAppActive() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationGetsOfferingsIfAppActiveInCustomEntitlementComputation() {
        self.systemInfo = .init(finishTransactions: true, customEntitlementsComputation: true)
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationGetsOfflineEntitlementsIfAppActive() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfflineEntitlementsManager.invokedUpdateProductsEntitlementsCacheIfStaleCount)
            .toEventually(equal(1))
    }

    func testFirstInitializationDoesntFetchOfferingsOrOfflineEntitlementsIfAppBackgrounded() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCache) == false
        expect(self.mockOfflineEntitlementsManager.invokedUpdateProductsEntitlementsCacheIfStale) == false
    }

    func testProductDataIsCachedForOfferings() throws {
        self.setupPurchases()

        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(
            try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                contents: .mockContents,
                                                                loadedFromDiskCache: false))
        )

        let result: SK1Product? = waitUntilValue { completed in
            self.purchases.getOfferings { (newOfferings, _) in
                let storeProduct = newOfferings!["base"]!.monthly!.storeProduct

                self.purchases.purchase(product: storeProduct) { (_, _, _, _) in }

                let transaction = MockTransaction()
                transaction.mockPayment = self.storeKit1Wrapper.payment!

                transaction.mockState = SKPaymentTransactionState.purchasing
                self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

                self.backend.postReceiptResult = .success(CustomerInfo(testData: Self.emptyCustomerInfoData)!)

                transaction.mockState = SKPaymentTransactionState.purchased
                self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper, updatedTransaction: transaction)

                completed(storeProduct.sk1Product)
            }
        }

        let product = try XCTUnwrap(result)

        expect(self.backend.postReceiptDataCalled).to(beTrue())
        expect(self.backend.postedReceiptData).toNot(beNil())

        expect(self.backend.postedProductID) == product.productIdentifier
        expect(self.backend.postedPrice) == product.price as Decimal
        expect(self.backend.postedCurrencyCode) == product.priceLocale.currencyCode

        expect(self.storeKit1Wrapper.finishCalled).toEventually(beTrue())
    }

    func testCachedOfferingsEmptyByDefault() {
        self.setupPurchases()

        expect(self.purchases.cachedOfferings).to(beNil())
    }

    func testCachedOfferings() throws {
        self.setupPurchases()

        let offerings = try XCTUnwrap(self.offeringsFactory.createOfferings(from: [:],
                                                                            contents: .mockContents,
                                                                            loadedFromDiskCache: false))
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(offerings)

        expect(self.purchases.cachedOfferings) === offerings
    }

    func testInvalidateCustomerInfoCacheDoesntClearOfferingsCache() {
        self.setupPurchases()

        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0

        self.purchases.invalidateCustomerInfoCache()
        expect(self.deviceCache.clearOfferingsCacheTimestampCount) == 0
    }

    func testWarmsUpPaywallsCache() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let bundle = Bundle(for: Self.self)
        let offeringsURL = try XCTUnwrap(bundle.url(forResource: "Offerings",
                                                    withExtension: "json",
                                                    subdirectory: "Fixtures"))
        let offeringsResponse = try OfferingsResponse.create(with: XCTUnwrap(Data(contentsOf: offeringsURL)))

        let offering = Offering(
            identifier: "offering",
            serverDescription: "",
            paywall: nil,
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let offerings = Offerings(
            offerings: [
                offering.identifier: offering
            ],
            currentOfferingID: offering.identifier,
            placements: nil,
            targeting: nil,
            contents: .init(response: offeringsResponse,
                            httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )

        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.mockOfferingsManager.stubbedUpdateOfferingsCompletionResult = .success(
            OfferingsResultData(offerings: offerings,
                                requestedProductIds: [offering.identifier],
                                notFoundProductIds: [])
        )

        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))

        expect(self.paywallCache.invokedWarmUpEligibilityCache).toEventually(beTrue())
        expect(self.paywallCache.invokedWarmUpEligibilityCacheOfferings) == offerings

        expect(self.paywallCache.invokedWarmUpPaywallAssetsCache).toEventually(beTrue())
        expect(self.paywallCache.invokedWarmUpPaywallAssetsCacheOfferings) == offerings
    }

    func testGetOfferingsWarmsUpEligibilityCache() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()

        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(from: [:],
                                                  contents: .mockContents,
                                                  loadedFromDiskCache: false)
        )
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(offerings)

        // Reset any warm-up that may have been triggered during configure.
        self.paywallCache.invokedWarmUpEligibilityCache = false
        self.paywallCache.invokedWarmUpEligibilityCacheOfferings = nil

        waitUntil { completed in
            self.purchases.getOfferings { _, _ in
                completed()
            }
        }

        expect(self.paywallCache.invokedWarmUpEligibilityCache).toEventually(beTrue())
        expect(self.paywallCache.invokedWarmUpEligibilityCacheOfferings) === offerings
    }

    // MARK: - overridePreferredUILocale

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    @MainActor
    func testEligibilityWarmupOutlivesPurchasesUntilBothOfferingChecksComplete() async throws {
        let checker = HeldEligibilityChecker()
        var cache: PaywallCacheWarming? = PaywallCacheWarming(introEligibiltyChecker: checker)
        weak var observedCache = cache
        let lifetimes = DeallocationTracker()
        do {
            let cacheInterface: PaywallCacheWarmingType = try XCTUnwrap(cache)
            XCTAssertTrue(cacheInterface as AnyObject === cache)
            lifetimes.track(cacheInterface as AnyObject)
        }
        let offerings = ["current", "remaining"].map { identifier in
            Offering(
                identifier: identifier,
                serverDescription: identifier,
                paywall: nil,
                availablePackages: [.init(
                    identifier: "$rc_monthly",
                    packageType: .monthly,
                    storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: identifier)),
                    offeringIdentifier: identifier,
                    webCheckoutUrl: nil
                )],
                webCheckoutUrl: nil
            )
        }
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.mockOperationDispatcher.forwardToOriginalDispatchOnWorkerThread = true
        self.initializePurchasesInstance(appUserId: "test", paywallCache: cache)
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(.init(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: "current",
            placements: nil,
            targeting: nil,
            contents: .mockContents,
            loadedFromDiskCache: false
        ))

        _ = try await self.purchases.offerings()
        await expect { checker.requests.value }.toEventually(equal([["current"]]))
        weak var observedPurchases = self.purchases
        Purchases.clearSingleton()
        self.purchases = nil
        cache = nil

        await expect { observedPurchases == nil }.toEventually(beTrue())
        expect(observedCache).toNot(beNil())
        let barrierStarted: Atomic<Bool> = false
        let barrierFinished: Atomic<Bool> = false
        let barrier = Task { @MainActor in
            barrierStarted.value = true
            try await lifetimes.waitForDeallocation(timeout: .seconds(2))
            barrierFinished.value = true
        }
        await expect { barrierStarted.value }.toEventually(beTrue())
        expect(barrierFinished.value) == false
        checker.completeNext()

        await expect { checker.requests.value }.toEventually(equal([["current"], ["remaining"]]))
        expect(observedCache).toNot(beNil())
        expect(barrierFinished.value) == false
        checker.completeNext()
        try await barrier.value
        expect(barrierFinished.value) == true
        await expect { observedCache == nil }.toEventually(beTrue())
    }

    @MainActor
    func testCacheLifetimeBarrierFailsWhenAnInstanceRemainsAlive() async throws {
        let lifetimes = DeallocationTracker()
        let object = NSObject()
        lifetimes.track(object)
        defer { withExtendedLifetime(object) {} }
        var threw = false
        let assertions = await gatherExpectations(silently: true) {
            do {
                try await lifetimes.waitForDeallocation(timeout: .milliseconds(10))
            } catch {
                threw = true
            }
        }

        expect(threw) == true
        expect(lifetimes.pendingCount) == 1
        let failure = try XCTUnwrap(assertions.onlyElement)
        expect(failure.success) == false
        expect(failure.message.stringValue).to(contain("1 cache instances remain"))
    }

    func testOverridePreferredUILocaleInvalidatesInMemoryCache() {
        self.setupPurchases()

        self.mockOfferingsManager.invokedClearInMemoryOfferingsCache = false
        self.mockOfferingsManager.invokedOfferingsCount = 0

        self.purchases.overridePreferredUILocale("fr_FR")

        expect(self.mockOfferingsManager.invokedClearInMemoryOfferingsCache) == true
        expect(self.mockOfferingsManager.invokedClearInMemoryOfferingsCacheCount) == 1
    }

    func testOverridePreferredUILocaleRefetchesOfferings() {
        self.setupPurchases()

        self.mockOfferingsManager.invokedOfferingsCount = 0

        self.purchases.overridePreferredUILocale("de_DE")

        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }

    func testOverridePreferredUILocaleDoesNothingWhenLocaleUnchanged() {
        self.setupPurchases()

        self.purchases.overridePreferredUILocale("it_IT")
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCache = false
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCacheCount = 0
        self.mockOfferingsManager.invokedOfferingsCount = 0

        // Call again with the same locale
        self.purchases.overridePreferredUILocale("it_IT")

        expect(self.mockOfferingsManager.invokedClearInMemoryOfferingsCache) == false
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testOverridePreferredUILocaleDoesNotInvalidateOrFetchWhenRateLimited() {
        self.setupPurchases()

        // Exhaust the rate limiter (maxCalls: 2)
        self.purchases.overridePreferredUILocale("fr_FR")
        self.purchases.overridePreferredUILocale("de_DE")

        // Reset counters after exhausting the rate limiter
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCache = false
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCacheCount = 0
        self.mockOfferingsManager.invokedOfferingsCount = 0

        // Third call should be fully rate-limited
        self.purchases.overridePreferredUILocale("es_ES")

        expect(self.mockOfferingsManager.invokedClearInMemoryOfferingsCache) == false
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 0
    }

    func testOverridePreferredUILocaleWithNilClearsOverride() {
        self.setupPurchases()

        self.purchases.overridePreferredUILocale("fr_FR")
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCache = false
        self.mockOfferingsManager.invokedClearInMemoryOfferingsCacheCount = 0
        self.mockOfferingsManager.invokedOfferingsCount = 0

        self.purchases.overridePreferredUILocale(nil)

        expect(self.mockOfferingsManager.invokedClearInMemoryOfferingsCache) == true
        expect(self.mockOfferingsManager.invokedOfferingsCount) == 1
    }

    // MARK: - UI preview mode

    func testFirstInitializationInUIPreviewModeDoesGetOfferingsIfAppActive() {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         uiPreviewMode: true,
                                         storeKitVersion: self.storeKitVersion,
                                         clock: self.clock)
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toEventually(equal(1))
    }

    func testFirstInitializationInUIPreviewModeDoesNotGetOfferingsIfAppBackgrounded() {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         uiPreviewMode: true,
                                         storeKitVersion: self.storeKitVersion,
                                         clock: self.clock)
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount).toAlways(equal(0))
    }

}
