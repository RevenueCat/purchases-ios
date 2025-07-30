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
        let product = TestStoreMockData.yearlyProduct

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

        // For now, free trials and intro offers are not supported for TestStoreProducts coming from WebProducts
        expect(storeProduct.introductoryDiscount).to(beNil())
        expect(storeProduct.discounts).to(beEmpty())
    }

    func testOneTimePurchaseWebProductToStoreProductConversion() throws {
        let product = TestStoreMockData.lifetimeProduct

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
