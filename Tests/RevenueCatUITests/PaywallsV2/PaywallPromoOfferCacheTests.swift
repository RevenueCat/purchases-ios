//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPromoOfferCacheTests.swift
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallPromoOfferCacheTests: TestCase {

    private static let promoCode = "promo_code"

    // Both `PaywallView` initializers map their `simulatePromoEligible` flag through this factory.
    // It is the single mapping site: if it stops producing a cache, every promo preview silently
    // falls back to real eligibility, which cannot resolve for the mock products previews use.
    func testSimulatedBuildsACacheOnlyWhenEligibilityIsSimulated() {
        XCTAssertNotNil(PaywallPromoOfferCache.simulated(if: true))
        XCTAssertNil(PaywallPromoOfferCache.simulated(if: false))
    }

    func testSimulatedCacheFabricatesOffersInsteadOfFetchingThem() async throws {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let cache = try XCTUnwrap(PaywallPromoOfferCache.simulated(if: true))

        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertNotNil(cache.get(for: package), "A simulated cache seeds a display-only signed offer.")
        let purchasableOffer = await cache.purchasableOffer(for: package)
        XCTAssertNil(purchasableOffer, "A fabricated offer must never reach StoreKit.")
    }

    func testSimulateEligibleSeedsSignedOfferForMatchingDiscount() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let cache = PaywallPromoOfferCache(simulateEligible: true)

        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertNotNil(
            cache.get(for: package),
            "Simulate mode should fabricate a signed promo offer for a package with a matching discount."
        )
        XCTAssertTrue(cache.isMostLikelyEligible(for: package))
    }

    func testSimulateEligibleDoesNotExposeOfferToPurchasePath() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let cache = PaywallPromoOfferCache(simulateEligible: true)

        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertNotNil(
            cache.get(for: package),
            "Display paths still read the fabricated offer."
        )
        let purchasableOffer = await cache.purchasableOffer(for: package)
        XCTAssertNil(
            purchasableOffer,
            "A fabricated offer carries sentinel signing data and must never reach a real purchase."
        )
    }

    func testSimulateEligibleSeededOfferDrivesRenderedPromoPrice() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let cache = PaywallPromoOfferCache(simulateEligible: true)
        await cache.computeEligibility(for: [(package, Self.promoCode)])

        let handler = Self.makeVariableHandler()
        let locale = Locale(identifier: "en_US")

        // With the simulated offer seeded, the promo price variable renders the discounted price...
        let withPromo = handler.processVariables(
            in: "{{ product.offer_price }}",
            with: package,
            locale: locale,
            localizations: [:],
            isEligibleForIntroOffer: false,
            promoOffer: cache.get(for: package)
        )
        XCTAssertEqual(withPromo, "$1.99")

        // ...and without it the same variable falls back to the base price.
        let withoutPromo = handler.processVariables(
            in: "{{ product.offer_price }}",
            with: package,
            locale: locale,
            localizations: [:],
            isEligibleForIntroOffer: false,
            promoOffer: nil
        )
        XCTAssertEqual(withoutPromo, "$3.99")
    }

    func testSimulateEligibleIgnoresPackagesWithoutMatchingDiscount() async {
        // Product carries no discount matching the configured promo code.
        let package = Self.makePackage(promoDiscountIdentifier: "some_other_code")
        let cache = PaywallPromoOfferCache(simulateEligible: true)

        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertNil(
            cache.get(for: package),
            "No matching discount means no fabricated offer, so promo pricing must not resolve."
        )
        XCTAssertFalse(
            cache.isMostLikelyEligible(for: package),
            "Without a matching discount or subscription history the package stays ineligible."
        )
    }

    func testColdChecksStartConcurrently() async {
        let firstPackage = Self.makePackage(productIdentifier: "first")
        let secondPackage = Self.makePackage(productIdentifier: "second")
        let fetcher = SuspendedOfferFetcher()
        let cache = Self.makeCache(offerFetcher: fetcher.fetch)

        let computation = Task { @MainActor in
            await cache.computeEligibility(for: [
                (firstPackage, Self.promoCode),
                (secondPackage, Self.promoCode)
            ])
        }

        await fetcher.waitForCallCount(2)
        XCTAssertEqual(fetcher.callCount, 2, "Every cold check must start before the first result is awaited.")

        fetcher.resumeAll()
        await computation.value

        XCTAssertNotNil(cache.get(for: firstPackage))
        XCTAssertNotNil(cache.get(for: secondPackage))
    }

    func testDuplicateConcurrentChecksCoalesceAndSubsequentChecksUseCache() async {
        let package = Self.makePackage()
        let fetcher = SuspendedOfferFetcher()
        let cache = Self.makeCache(offerFetcher: fetcher.fetch)

        let firstComputation = Task { @MainActor in
            await cache.computeEligibility(for: [(package, Self.promoCode)])
        }
        await fetcher.waitForCallCount(1)

        let duplicateComputation = Task { @MainActor in
            await cache.computeEligibility(for: [(package, Self.promoCode)])
        }
        for _ in 0..<10 {
            await Task.yield()
        }

        XCTAssertEqual(fetcher.callCount, 1)
        fetcher.resumeAll()
        await firstComputation.value
        await duplicateComputation.value

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(fetcher.callCount, 1, "A fresh cached signature must not make another request.")
    }

    func testTimeoutDoesNotBlockAndRemainsRetryable() async {
        let package = Self.makePackage()
        let fetcher = SuspendedOfferFetcher()
        let cache = Self.makeCache(requestTimeout: 0.01, offerFetcher: fetcher.fetch)

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(fetcher.callCount, 1)
        XCTAssertNil(cache.get(for: package))

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(fetcher.callCount, 2, "A timed-out request must not be cached as ineligible.")

        fetcher.resumeAll()
    }

    func testTransientFailuresAreNotCached() async {
        let package = Self.makePackage()
        var callCount = 0
        let cache = Self.makeCache { _, _ in
            callCount += 1
            throw NSError(domain: "PaywallPromoOfferCacheTests", code: 1)
        }

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertEqual(callCount, 2)
        XCTAssertNil(cache.get(for: package))
    }

    func testIneligibleResultIsCached() async {
        let package = Self.makePackage()
        var callCount = 0
        let cache = Self.makeCache { _, _ in
            callCount += 1
            throw ErrorCode.ineligibleError
        }

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertEqual(callCount, 1)
        XCTAssertNil(cache.get(for: package))
    }

    func testDifferentPromoCodesUseDistinctCacheEntries() async {
        let secondPromoCode = "second_promo_code"
        let package = Self.makePackage(additionalPromoDiscountIdentifiers: [secondPromoCode])
        var callCount = 0
        let cache = Self.makeCache { discount, _ in
            callCount += 1
            return Self.makeOffer(discount: discount)
        }

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        await cache.computeEligibility(for: [(package, secondPromoCode)])
        XCTAssertEqual(callCount, 2)

        await cache.computeEligibility(for: [
            (package, Self.promoCode),
            (package, secondPromoCode)
        ])
        XCTAssertEqual(callCount, 2)
    }

    func testIdentityAndConfigurationChangesInvalidateCache() async {
        let package = Self.makePackage()
        var appUserID = "first-user"
        var purchasesInstance = NSObject()
        var callCount = 0
        let cache = PaywallPromoOfferCache(
            requestTimeout: 1,
            appUserIDProvider: { appUserID },
            purchasesInstanceProvider: { ObjectIdentifier(purchasesInstance) },
            offerFetcher: { discount, _ in
                callCount += 1
                return Self.makeOffer(discount: discount)
            }
        )

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(callCount, 1)

        appUserID = "second-user"
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(callCount, 2)

        purchasesInstance = NSObject()
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertEqual(callCount, 3)
    }

    func testConfigurationChangeDoesNotCoalesceWithOldInFlightRequest() async {
        let package = Self.makePackage()
        var purchasesInstance = NSObject()
        let fetcher = SuspendedOfferFetcher()
        let cache = PaywallPromoOfferCache(
            requestTimeout: 1,
            appUserIDProvider: { "user" },
            purchasesInstanceProvider: { ObjectIdentifier(purchasesInstance) },
            offerFetcher: fetcher.fetch
        )

        let oldConfigurationCheck = Task { @MainActor in
            await cache.computeEligibility(for: [(package, Self.promoCode)])
        }
        await fetcher.waitForCallCount(1)

        purchasesInstance = NSObject()
        let newConfigurationCheck = Task { @MainActor in
            await cache.computeEligibility(for: [(package, Self.promoCode)])
        }
        await fetcher.waitForCallCount(2)

        fetcher.resumeAll()
        await oldConfigurationCheck.value
        await newConfigurationCheck.value

        XCTAssertEqual(fetcher.callCount, 2)
        XCTAssertNotNil(cache.get(for: package))
    }

    func testPurchaseUsesFreshSignatureAndRefreshesExpiredSignature() async {
        let package = Self.makePackage()
        var now = Date(timeIntervalSince1970: 1_000_000)
        var callCount = 0
        let cache = PaywallPromoOfferCache(
            requestTimeout: 1,
            appUserIDProvider: { "user" },
            purchasesInstanceProvider: { nil },
            dateProvider: { now },
            offerFetcher: { discount, _ in
                callCount += 1
                return Self.makeOffer(
                    discount: discount,
                    timestamp: Int(now.timeIntervalSince1970 * 1_000)
                )
            }
        )

        await cache.computeEligibility(for: [(package, Self.promoCode)])
        let freshOffer = await cache.purchasableOffer(for: package)
        XCTAssertNotNil(freshOffer)
        XCTAssertEqual(callCount, 1, "A valid signature must go directly to purchase.")

        now.addTimeInterval(24 * 60 * 60)
        let refreshedOffer = await cache.purchasableOffer(for: package)
        XCTAssertNotNil(refreshedOffer)
        XCTAssertEqual(callCount, 2, "An expired signature must be refreshed at purchase time.")
    }

    func testConcurrentResultsPublishOnce() async {
        let firstPackage = Self.makePackage(productIdentifier: "first")
        let secondPackage = Self.makePackage(productIdentifier: "second")
        let cache = Self.makeCache { discount, _ in
            return Self.makeOffer(discount: discount)
        }
        var publicationCount = 0
        let cancellable = cache.objectWillChange.sink {
            publicationCount += 1
        }

        await cache.computeEligibility(for: [
            (firstPackage, Self.promoCode),
            (secondPackage, Self.promoCode)
        ])

        XCTAssertEqual(publicationCount, 1)
        withExtendedLifetime(cancellable) {}
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallPromoOfferCacheTests {

    static func makeVariableHandler() -> VariableHandlerV2 {
        return VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            dateProvider: { Date(timeIntervalSince1970: 0) }
        )
    }

    static func makeCache(
        requestTimeout: TimeInterval = 1,
        offerFetcher: @escaping PaywallPromoOfferCache.OfferFetcher
    ) -> PaywallPromoOfferCache {
        return PaywallPromoOfferCache(
            requestTimeout: requestTimeout,
            appUserIDProvider: { "user" },
            purchasesInstanceProvider: { nil },
            offerFetcher: offerFetcher
        )
    }

    static func makeOffer(
        discount: StoreProductDiscount,
        timestamp: Int = Int(Date().timeIntervalSince1970 * 1_000)
    ) -> PromotionalOffer {
        return discount.promotionalOffer(
            withSignedDataIdentifier: discount.offerIdentifier ?? promoCode,
            keyIdentifier: "key",
            nonce: UUID(),
            signature: "signature",
            timestamp: timestamp
        )
    }

    static func makePackage(
        promoDiscountIdentifier: String = promoCode,
        productIdentifier: String = "com.revenuecat.monthly",
        additionalPromoDiscountIdentifiers: [String] = []
    ) -> Package {
        let promoDiscountIdentifiers = [promoDiscountIdentifier] + additionalPromoDiscountIdentifiers
        let product = TestStoreProduct(
            localizedTitle: "PRO monthly",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "Monthly subscription",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            discounts: promoDiscountIdentifiers.map {
                TestStoreProductDiscount(
                    identifier: $0,
                    price: 1.99,
                    localizedPriceString: "$1.99",
                    paymentMode: .payAsYouGo,
                    subscriptionPeriod: .init(value: 1, unit: .month),
                    numberOfPeriods: 3,
                    type: .promotional
                )
            },
            locale: Locale(identifier: "en_US")
        )

        return Package(
            identifier: "monthly",
            packageType: .monthly,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class SuspendedOfferFetcher {

    private(set) var callCount = 0
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func fetch(discount: StoreProductDiscount, product: StoreProduct) async throws -> PromotionalOffer {
        self.callCount += 1
        await withCheckedContinuation { continuation in
            self.continuations.append(continuation)
        }
        return PaywallPromoOfferCacheTests.makeOffer(discount: discount)
    }

    func waitForCallCount(_ expectedCount: Int) async {
        while self.callCount < expectedCount {
            await Task.yield()
        }
    }

    func resumeAll() {
        let continuations = self.continuations
        self.continuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

}

#endif
