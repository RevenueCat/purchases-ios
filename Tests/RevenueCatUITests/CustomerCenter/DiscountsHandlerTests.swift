//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiscountsHandlerTests.swift
//
//  Created by Facundo Menzella on 14/5/25.

import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, *)
final class DiscountsHandlerTests: TestCase {

    private var mockProvider: MockCustomerCenterPurchases!

    func test_crossProductPromotion_resolvesSuccessfully() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscripedProduct = TestStoreProduct(
            localizedTitle: "subscripedProduct",
            price: 1.99,
            localizedPriceString: "subscripedProduct",
            productIdentifier: "subscripedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )

        let targetProduct = TestStoreProduct(
            localizedTitle: "localizedTitle",
            price: 1.99,
            localizedPriceString: "localizedPriceString",
            productIdentifier: "targetProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )

        mockProvider = MockCustomerCenterPurchases(
            products: [targetProduct.toStoreProduct(), subscripedProduct.toStoreProduct()]
        )

        let crossPromotion = CustomerCenterConfigData.HelpPath.PromotionalOffer.CrossProductPromotion(
            storeofferingidentifier: discount.identifier,
            targetproductid: targetProduct.productIdentifier
        )
        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: [:],
            crossProductPromotions: [
                subscripedProduct.productIdentifier: crossPromotion
            ]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        let (resolvedDiscount, resolvedProduct) = try await finder.findDiscount(
            for: subscripedProduct.toStoreProduct(),
            productIdentifier: subscripedProduct.productIdentifier,
            promoOfferDetails: promo
        )

        XCTAssertEqual(resolvedDiscount.offerIdentifier, discount.identifier)
        XCTAssertEqual(resolvedProduct.productIdentifier, targetProduct.productIdentifier)
    }
}
