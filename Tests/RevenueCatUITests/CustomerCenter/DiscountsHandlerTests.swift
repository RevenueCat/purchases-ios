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

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

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
            products: [targetProduct.toStoreProduct(), subscribedStoreProduct]
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
                subscribedProduct.productIdentifier: crossPromotion
            ]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        let (resolvedDiscount, resolvedProduct) = try await finder.findDiscount(
            for: subscribedStoreProduct,
            promoOfferDetails: promo
        )

        expect(resolvedDiscount.offerIdentifier) == discount.identifier
        expect(resolvedProduct.productIdentifier) == targetProduct.productIdentifier
    }

    func test_crossProductPromotion_productNotFound() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

        mockProvider = MockCustomerCenterPurchases(
            products: []
        )

        let crossPromotion = CustomerCenterConfigData.HelpPath.PromotionalOffer.CrossProductPromotion(
            storeofferingidentifier: discount.identifier,
            targetproductid: "targetProduct"
        )
        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: [:],
            crossProductPromotions: [
                subscribedProduct.productIdentifier: crossPromotion
            ]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        await XCTAssertThrowsErrorAsync(
            try await finder.findDiscount(
                for: subscribedStoreProduct,
                promoOfferDetails: promo
            ),
            CustomerCenterError.couldNotFindSubscriptionInformation
        )
    }

    func test_crossProductPromotion_promoNotFound() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

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
            products: [targetProduct.toStoreProduct(), subscribedStoreProduct]
        )

        let crossPromotion = CustomerCenterConfigData.HelpPath.PromotionalOffer.CrossProductPromotion(
            storeofferingidentifier: "not_found",
            targetproductid: "targetProduct"
        )
        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: [:],
            crossProductPromotions: [
                subscribedProduct.productIdentifier: crossPromotion
            ]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        await XCTAssertThrowsErrorAsync(
            try await finder.findDiscount(
                for: subscribedStoreProduct,
                promoOfferDetails: promo
            ),
            CustomerCenterError.couldNotFindSubscriptionInformation
        )
    }

    func test_productMapping_resolvesSuccessfully() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

        mockProvider = MockCustomerCenterPurchases(
            products: [subscribedStoreProduct]
        )

        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: ["subscribedProduct": "cross_offer"],
            crossProductPromotions: [:]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        let (resolvedDiscount, resolvedProduct) = try await finder.findDiscount(
            for: subscribedStoreProduct,
            promoOfferDetails: promo
        )

        expect(resolvedDiscount.offerIdentifier) == discount.identifier
        expect(resolvedProduct.productIdentifier) == subscribedProduct.productIdentifier
    }

    func test_productMapping_productNotFound() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

        mockProvider = MockCustomerCenterPurchases(
            products: [subscribedStoreProduct]
        )

        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: ["not_found_product": "cross_offer"],
            crossProductPromotions: [:]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        await XCTAssertThrowsErrorAsync(
            try await finder.findDiscount(
                for: subscribedStoreProduct,
                promoOfferDetails: promo
            ),
            CustomerCenterError.couldNotFindSubscriptionInformation
        )
    }

    func test_productMapping_promoNotFound() async throws {
        let discount = TestStoreProductDiscount(
            identifier: "cross_offer",
            price: 0.99,
            localizedPriceString: "0.99 USD",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let subscribedProduct = TestStoreProduct(
            localizedTitle: "subscribedProduct",
            price: 1.99,
            localizedPriceString: "subscribedProduct",
            productIdentifier: "subscribedProduct",
            productType: .autoRenewableSubscription,
            localizedDescription: "localizedDescription",
            discounts: [discount]
        )
        let subscribedStoreProduct = subscribedProduct.toStoreProduct()

        mockProvider = MockCustomerCenterPurchases(
            products: [subscribedStoreProduct]
        )

        let promo = CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "iosOfferId",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: ["subscribedProduct": "not_found_offer"],
            crossProductPromotions: [:]
        )

        let finder = DiscountsHandler(purchasesProvider: mockProvider)

        await XCTAssertThrowsErrorAsync(
            try await finder.findDiscount(
                for: subscribedStoreProduct,
                promoOfferDetails: promo
            ),
            CustomerCenterError.couldNotFindSubscriptionInformation
        )
    }
}

#endif
