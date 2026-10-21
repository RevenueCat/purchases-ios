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
                            productIdentifier: String = "com.revenuecat.monthly") -> Package {
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
