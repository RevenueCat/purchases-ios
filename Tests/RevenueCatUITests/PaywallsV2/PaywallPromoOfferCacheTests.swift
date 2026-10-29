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

@_spi(Internal) @testable import RevenueCat
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
        XCTAssertNil(cache.purchasableOffer(for: package), "A fabricated offer must never reach StoreKit.")
    }

    func testSimulatedIneligibleCacheNeverFetchesSignedOffers() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let cache = PaywallPromoOfferCache(simulateEligible: false)

        await cache.computeEligibility(for: [(package, Self.promoCode)])

        XCTAssertNil(cache.get(for: package))
        XCTAssertNil(cache.purchasableOffer(for: package))
        XCTAssertFalse(cache.isMostLikelyEligible(for: package))
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
        XCTAssertNil(
            cache.purchasableOffer(for: package),
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

    func testFetchesAllMatchingPackagesInOneBatchAndCachesTheirOwnOffers() async throws {
        let monthly = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let annual = Self.makePackage(promoDiscountIdentifier: "annual-promo", productIdentifier: "annual")
        let noCode = Self.makePackage(promoDiscountIdentifier: Self.promoCode, productIdentifier: "no-code")
        let mismatch = Self.makePackage(promoDiscountIdentifier: "other", productIdentifier: "mismatch")
        var batches: [[PromotionalOfferRequest]] = []
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            batches.append(requests)
            return requests.map { Self.result(for: $0) }
        }

        await cache.computeEligibility(for: [(monthly, Self.promoCode), (annual, "annual-promo"),
                                              (noCode, nil), (mismatch, Self.promoCode)])

        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].map { $0.product.productIdentifier },
                       [monthly.storeProduct.productIdentifier, annual.storeProduct.productIdentifier])
        XCTAssertEqual(cache.get(for: monthly)?.signedData.identifier, Self.promoCode)
        XCTAssertEqual(cache.get(for: annual)?.signedData.identifier, "annual-promo")
        XCTAssertTrue(cache.purchasableOffer(for: monthly) === cache.get(for: monthly))
        XCTAssertNil(cache.get(for: noCode))
        XCTAssertNil(cache.get(for: mismatch))
    }

    func testBatchFailureForOnePackagePreservesSuccessfulPackage() async {
        let monthly = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let annual = Self.makePackage(promoDiscountIdentifier: Self.promoCode, productIdentifier: "annual")
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return [Self.result(for: requests[0]),
                    PromotionalOfferResult(request: requests[1], result: .failure(ErrorUtils.ineligibleError()))]
        }

        await cache.computeEligibility(for: [(monthly, Self.promoCode), (annual, Self.promoCode)])

        XCTAssertNotNil(cache.purchasableOffer(for: monthly))
        XCTAssertNil(cache.purchasableOffer(for: annual))
        XCTAssertFalse(cache.isMostLikelyEligible(for: annual))
    }

    func testBatchResultMappingDoesNotDependOnResultOrder() async {
        let monthly = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let annual = Self.makePackage(promoDiscountIdentifier: "annual-promo", productIdentifier: "annual")
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return requests.reversed().map { Self.result(for: $0) }
        }
        await cache.computeEligibility(for: [(monthly, Self.promoCode), (annual, "annual-promo")])
        XCTAssertEqual(cache.get(for: monthly)?.signedData.identifier, Self.promoCode)
        XCTAssertEqual(cache.get(for: annual)?.signedData.identifier, "annual-promo")
    }

    func testBatchKeepsBillingPlanResultsSeparate() async {
        let upfront = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let installments = Self.makePackage(promoDiscountIdentifier: "installments-promo", hasBillingPlan: true)
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return [Self.result(for: requests[0]),
                    PromotionalOfferResult(request: requests[1], result: .failure(ErrorUtils.ineligibleError()))]
        }

        XCTAssertEqual(upfront.storeProduct.productIdentifier, installments.storeProduct.productIdentifier)
        XCTAssertNotEqual(upfront.storeProduct.id, installments.storeProduct.id)
        await cache.computeEligibility(for: [(upfront, Self.promoCode), (installments, "installments-promo")])

        XCTAssertNotNil(cache.purchasableOffer(for: upfront))
        XCTAssertTrue(cache.isMostLikelyEligible(for: upfront))
        XCTAssertNil(cache.purchasableOffer(for: installments))
        XCTAssertFalse(cache.isMostLikelyEligible(for: installments))
    }

    func testConcurrentBillingPlanRefreshesPreserveBothOffers() async {
        let upfront = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let installments = Self.makePackage(promoDiscountIdentifier: "installments-promo", hasBillingPlan: true)
        var pending: CheckedContinuation<[PromotionalOfferResult], Never>?
        var upfrontResults: [PromotionalOfferResult] = []
        let started = self.expectation(description: "Upfront request suspended")
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            if requests[0].product.id == upfront.storeProduct.id {
                upfrontResults = requests.map { Self.result(for: $0) }
                return await withCheckedContinuation {
                    pending = $0
                    started.fulfill()
                }
            }
            return requests.map { Self.result(for: $0) }
        }
        let upfrontRefresh = Task { await cache.computeEligibility(for: [(upfront, Self.promoCode)]) }
        await self.fulfillment(of: [started], timeout: 1)
        await cache.computeEligibility(for: [(installments, "installments-promo")])
        pending?.resume(returning: upfrontResults)
        await upfrontRefresh.value

        XCTAssertEqual(cache.get(for: upfront)?.signedData.identifier, Self.promoCode)
        XCTAssertEqual(cache.get(for: installments)?.signedData.identifier, "installments-promo")
    }

    func testFailedRefreshRemovesPreviousSignedOffer() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        var shouldFail = false
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return requests.map { request in
                shouldFail
                    ? PromotionalOfferResult(request: request, result: .failure(ErrorUtils.ineligibleError()))
                    : Self.result(for: request)
            }
        }
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNotNil(cache.purchasableOffer(for: package))

        shouldFail = true
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNil(cache.get(for: package))
        XCTAssertNil(cache.purchasableOffer(for: package))
    }

    func testPublishesOnceForEntireBatch() async {
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return requests.map { Self.result(for: $0) }
        }
        var updates = 0
        let observation = cache.objectWillChange.sink { updates += 1 }
        let packages = [Self.makePackage(promoDiscountIdentifier: Self.promoCode),
                        Self.makePackage(promoDiscountIdentifier: Self.promoCode, productIdentifier: "annual")]
        await cache.computeEligibility(for: packages.map { ($0, Self.promoCode) })
        XCTAssertEqual(updates, 1)
        withExtendedLifetime(observation) {}
    }

    func testEmptyRefreshRemovesPreviousSignedOffer() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        var omitResults = false
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            return omitResults ? [] : requests.map { Self.result(for: $0) }
        }
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNotNil(cache.purchasableOffer(for: package))
        omitResults = true
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNil(cache.purchasableOffer(for: package))
    }

    func testUserChangeRejectsCachedOffersIncludingProductsNotInNextBatch() async {
        let monthly = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let annual = Self.makePackage(promoDiscountIdentifier: Self.promoCode, productIdentifier: "annual")
        var appUserID = "A"
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil, appUserID: { appUserID },
                                           promotionalOffers: { requests in
            return requests.map { Self.result(for: $0) }
        })
        await cache.computeEligibility(for: [(monthly, Self.promoCode), (annual, Self.promoCode)])
        XCTAssertNotNil(cache.purchasableOffer(for: annual))

        appUserID = "B"
        XCTAssertNil(cache.get(for: monthly))
        XCTAssertNil(cache.purchasableOffer(for: annual))
        XCTAssertFalse(cache.isMostLikelyEligible(for: annual))

        await cache.computeEligibility(for: [(monthly, Self.promoCode)])
        XCTAssertNotNil(cache.purchasableOffer(for: monthly))
        XCTAssertNil(cache.purchasableOffer(for: annual))
    }

    func testUserChangeDuringRefreshRejectsBothCachedAndNewOffers() async {
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        var appUserID = "A"
        var switchUser = false
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil, appUserID: { appUserID },
                                           promotionalOffers: { requests in
            if switchUser { appUserID = "B" }
            return requests.map { Self.result(for: $0) }
        })
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNotNil(cache.purchasableOffer(for: package))

        switchUser = true
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNil(cache.get(for: package))
        XCTAssertNil(cache.purchasableOffer(for: package))
    }

    func testOlderRefreshCannotReplaceNewerOffer() async throws {
        for nextUserID in ["A", "B"] {
            let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
            var appUserID = "A"
            var requestsCount = 0
            var pending: CheckedContinuation<[PromotionalOfferResult], Never>?
            var olderResults: [PromotionalOfferResult] = []
            let started = self.expectation(description: "First request suspended")
            let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil, appUserID: { appUserID },
                                               promotionalOffers: { requests in
                requestsCount += 1
                if requestsCount == 1 {
                    olderResults = requests.map { Self.result(for: $0) }
                    return await withCheckedContinuation {
                        pending = $0
                        started.fulfill()
                    }
                }
                return requests.map { Self.result(for: $0) }
            })
            let olderRefresh = Task { await cache.computeEligibility(for: [(package, Self.promoCode)]) }
            await self.fulfillment(of: [started], timeout: 1)
            appUserID = nextUserID
            await cache.computeEligibility(for: [(package, Self.promoCode)])
            let currentOffer = try XCTUnwrap(cache.purchasableOffer(for: package))
            pending?.resume(returning: olderResults)
            await olderRefresh.value

            XCTAssertTrue(cache.purchasableOffer(for: package) === currentOffer)
        }
    }

    func testDisjointAndEmptyRefreshesDoNotDiscardPendingOffers() async {
        let monthly = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        let annual = Self.makePackage(promoDiscountIdentifier: Self.promoCode, productIdentifier: "annual")
        var pending: CheckedContinuation<[PromotionalOfferResult], Never>?
        var monthlyResults: [PromotionalOfferResult] = []
        let started = self.expectation(description: "Monthly request suspended")
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { requests in
            if requests[0].product.productIdentifier == monthly.storeProduct.productIdentifier {
                monthlyResults = requests.map { Self.result(for: $0) }
                return await withCheckedContinuation {
                    pending = $0
                    started.fulfill()
                }
            }
            return requests.map { Self.result(for: $0) }
        }
        let monthlyRefresh = Task { await cache.computeEligibility(for: [(monthly, Self.promoCode)]) }
        await self.fulfillment(of: [started], timeout: 1)
        await cache.computeEligibility(for: [(annual, Self.promoCode)])
        await cache.computeEligibility(for: [])
        pending?.resume(returning: monthlyResults)
        await monthlyRefresh.value

        XCTAssertNotNil(cache.purchasableOffer(for: monthly))
        XCTAssertNotNil(cache.purchasableOffer(for: annual))
    }

    func testNoMatchingOffersDoesNotInvokeBatchAPI() async {
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil) { _ in
            XCTFail("No matching offers should require no request")
            return []
        }
        await cache.computeEligibility(for: [])
        await cache.computeEligibility(for: [(Self.makePackage(promoDiscountIdentifier: "other"), Self.promoCode)])
    }

    func testSimulatedOffersDoNotInvokeBatchAPI() async {
        let cache = PaywallPromoOfferCache(subscriptionHistoryTracker: nil, simulatedEligibility: true) { _ in
            XCTFail("Simulated offers should never contact the backend")
            return []
        }
        let package = Self.makePackage(promoDiscountIdentifier: Self.promoCode)
        await cache.computeEligibility(for: [(package, Self.promoCode)])
        XCTAssertNotNil(cache.get(for: package))
        XCTAssertNil(cache.purchasableOffer(for: package))
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

    static func result(for request: PromotionalOfferRequest) -> PromotionalOfferResult {
        let offer = PromotionalOffer(discount: request.discount,
                                     signedData: .init(identifier: request.discount.offerIdentifier!,
                                                       keyIdentifier: "key", nonce: UUID(), signature: "signature",
                                                       timestamp: 12345))
        return .init(request: request, result: .success(offer))
    }

    static func makePackage(promoDiscountIdentifier: String,
                            productIdentifier: String = "com.revenuecat.monthly",
                            hasBillingPlan: Bool = false) -> Package {
        var product = TestStoreProduct(
            localizedTitle: "PRO monthly",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "Monthly subscription",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            discounts: [
                TestStoreProductDiscount(
                    identifier: promoDiscountIdentifier,
                    price: 1.99,
                    localizedPriceString: "$1.99",
                    paymentMode: .payAsYouGo,
                    subscriptionPeriod: .init(value: 1, unit: .month),
                    numberOfPeriods: 3,
                    type: .promotional
                )
            ],
            locale: Locale(identifier: "en_US")
        )

        if hasBillingPlan {
            product.installmentsInfo = .init(
                commitmentInstallmentsCount: 12,
                commitmentInstallmentPeriod: .init(value: 1, unit: .month),
                installmentBillingPrice: 1,
                installmentBillingDisplayPrice: "$1",
                commitmentTotalPeriod: .init(value: 1, unit: .year),
                commitmentTotalPrice: 12,
                commitmentTotalDisplayPrice: "$12",
                billingPlanType: .monthly
            )
        }

        return Package(
            identifier: "monthly",
            packageType: .monthly,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
        )
    }

}

#endif
