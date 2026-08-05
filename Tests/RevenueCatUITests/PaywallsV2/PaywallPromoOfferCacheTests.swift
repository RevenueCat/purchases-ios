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

    static func makePackage(promoDiscountIdentifier: String) -> Package {
        let product = TestStoreProduct(
            localizedTitle: "PRO monthly",
            price: 3.99,
            currencyCode: "USD",
            localizedPriceString: "$3.99",
            productIdentifier: "com.revenuecat.monthly",
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
