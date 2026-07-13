//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebProductToStoreProductConversionTests.swift
//
//  Created by Antonio Pallares on 29/7/25.

import Nimble
@testable import RevenueCat
import XCTest

class WebProductToStoreProductConversionTests: TestCase {

    func testSubscriptionWebProductToStoreProductConversion() throws {
        let product = SimulatedStoreMockData.yearlyProduct

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "es_ES"))

        expect(storeProduct.productType) == .autoRenewableSubscription
        expect(storeProduct.productCategory) == .subscription
        expect(storeProduct.localizedDescription) == product.description
        expect(storeProduct.localizedTitle) == product.title
        expect(storeProduct.price) == 99.99
        expect(storeProduct.localizedPriceString) == "99,99 €"
        expect(storeProduct.productIdentifier) == product.identifier
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            expect(storeProduct.isFamilyShareable) == false
        }
        expect(storeProduct.subscriptionGroupIdentifier) == nil
        expect(storeProduct.subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)

        expect(storeProduct.introductoryDiscount).to(beNil())
        expect(storeProduct.discounts).to(beEmpty())
    }

    func testSubscriptionWebProductWithFreeTrialIncludesFreeTrialIntroductoryDiscount() throws {
        let product = SimulatedStoreMockData.yearlyProductWithFreeTrial

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "es_ES"))

        expect(storeProduct.price) == 99.99
        expect(storeProduct.localizedPriceString) == "99,99\u{00A0}€"
        expect(storeProduct.subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)

        let discount = try XCTUnwrap(storeProduct.introductoryDiscount)
        expect(discount.paymentMode) == .freeTrial
        expect(discount.type) == .introductory
        expect(discount.price) == 0
        expect(discount.localizedPriceString) == "0,00\u{00A0}€"
        expect(discount.subscriptionPeriod) == SubscriptionPeriod(value: 7, unit: .day)
        expect(discount.numberOfPeriods) == 1
        expect(discount.offerIdentifier) == "$rc_free_trial"

        expect(storeProduct.discounts).to(beEmpty())
    }

    func testSubscriptionWebProductWithIntroPriceIncludesPayAsYouGoIntroductoryDiscount() throws {
        let product = SimulatedStoreMockData.yearlyProductWithIntroPrice

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "es_ES"))

        expect(storeProduct.price) == 99.99
        expect(storeProduct.subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)

        let discount = try XCTUnwrap(storeProduct.introductoryDiscount)
        expect(discount.paymentMode) == .payAsYouGo
        expect(discount.type) == .introductory
        expect(discount.price) == 1.99
        expect(discount.localizedPriceString) == "1,99\u{00A0}€"
        expect(discount.subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .month)
        expect(discount.numberOfPeriods) == 3
        expect(discount.offerIdentifier) == "$rc_intro_price"

        expect(storeProduct.discounts).to(beEmpty())
    }

    func testSubscriptionWebProductWithFreeTrialAndIntroPricePrefersFreeTrial() throws {
        let product = SimulatedStoreMockData.yearlyProductWithFreeTrialAndIntroPrice

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "es_ES"))

        let discount = try XCTUnwrap(storeProduct.introductoryDiscount)
        expect(discount.paymentMode) == .freeTrial
        expect(discount.offerIdentifier) == "$rc_free_trial"
        expect(discount.subscriptionPeriod) == SubscriptionPeriod(value: 7, unit: .day)
        expect(discount.price) == 0

        expect(storeProduct.discounts).to(beEmpty())
    }

    func testSubscriptionWebProductWithMalformedTrialPeriodSkipsIntroductoryDiscount() throws {
        let product = SimulatedStoreMockData.yearlyProductWithMalformedTrialPeriod

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "es_ES"))

        expect(storeProduct.price) == 99.99
        expect(storeProduct.subscriptionPeriod) == SubscriptionPeriod(value: 1, unit: .year)
        expect(storeProduct.introductoryDiscount).to(beNil())
        expect(storeProduct.discounts).to(beEmpty())
    }

    func testOneTimePurchaseWebProductToStoreProductConversion() throws {
        let product = SimulatedStoreMockData.lifetimeProduct

        let storeProduct = try product.convertToStoreProduct(locale: Locale(identifier: "en_GB"))

        expect(storeProduct.productType) == .nonConsumable
        expect(storeProduct.productCategory) == .nonSubscription
        expect(storeProduct.localizedDescription) == product.description
        expect(storeProduct.localizedTitle) == product.title
        expect(storeProduct.price) == 199.90
        expect(storeProduct.localizedPriceString) == "£199.90"
        expect(storeProduct.productIdentifier) == product.identifier
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            expect(storeProduct.isFamilyShareable) == false
        }
        expect(storeProduct.subscriptionGroupIdentifier) == nil
        expect(storeProduct.subscriptionPeriod) == nil
        expect(storeProduct.introductoryDiscount).to(beNil())
        expect(storeProduct.discounts).to(beEmpty())
    }
}
