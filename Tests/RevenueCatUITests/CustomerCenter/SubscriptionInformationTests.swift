//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInformationTests.swift
//
//  Created by Cesar de la Vega on 10/25/24.

import Nimble
import XCTest

import RevenueCat
@testable import RevenueCatUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class SubscriptionInformationTests: TestCase {

    static let locale: Locale = .current

    func testAppleEntitlementAndSubscribedProduct() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithAppleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockProduct = TestStoreProduct(
            localizedTitle: "Monthly Product",
            price: 6.99,
            localizedPriceString: "$6.99",
            productIdentifier: entitlement.productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "PRO monthly",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement,
                                                                     subscribedProduct: mockProduct.toStoreProduct()))
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.durationTitle) == "1 month"
        expect(subscriptionInfo.explanation) == .earliestRenewal
        expect(subscriptionInfo.price) == .paid("$6.99")

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndNonRenewingSubscribedProduct() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithNonRenewingAppleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockProduct = TestStoreProduct(
            localizedTitle: "Monthly Product",
            price: 6.99,
            localizedPriceString: "$6.99",
            productIdentifier: entitlement.productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "PRO monthly",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement,
                                                                     subscribedProduct: mockProduct.toStoreProduct()))
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.durationTitle) == "1 month"
        expect(subscriptionInfo.explanation) == .earliestExpiration
        expect(subscriptionInfo.price) == .paid("$6.99")

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expires
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == false
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndExpiredSubscribedProduct() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithExpiredAppleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockProduct = TestStoreProduct(
            localizedTitle: "Monthly Product",
            price: 6.99,
            localizedPriceString: "$6.99",
            productIdentifier: entitlement.productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "PRO monthly",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement,
                                                                     subscribedProduct: mockProduct.toStoreProduct()))
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.durationTitle) == "1 month"
        expect(subscriptionInfo.explanation) == .expired
        expect(subscriptionInfo.price) == .paid("$6.99")

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expired
        expect(expirationOrRenewal.date) == .date("Apr 12, 2000")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == false
        expect(subscriptionInfo.store) == .appStore
    }

    func testInitWithGoogleEntitlement() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .earliestRenewal
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithGoogleEntitlementNonRenewing() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithNonRenewingGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .earliestExpiration
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expires
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == false
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithGoogleEntitlementExpired() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithExpiredGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .expired
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expired
        expect(expirationOrRenewal.date) == .date("Apr 12, 2000")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == false
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithPromotionalEntitlement() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithPromotional
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .promotional
        expect(subscriptionInfo.price) == .free

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expires
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == false
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .promotional
    }

    func testInitWithPromotionalLifetimeEntitlement() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithLifetimePromotional
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .promotional
        expect(subscriptionInfo.price) == .free

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expires
        expect(expirationOrRenewal.date) == .never

        expect(subscriptionInfo.willRenew) == false
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .promotional
    }

    func testInitWithStripeEntitlement() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .earliestRenewal
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithStripeEntitlementNonRenewing() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithNonRenewingStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .earliestExpiration
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expires
        expect(expirationOrRenewal.date) == .date("Apr 12, 2062")

        expect(subscriptionInfo.willRenew) == false
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == true
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithStripeEntitlementExpired() throws {
        let customerInfo = SubscriptionInformationFixtures.customerInfoWithExpiredStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionInfo = try XCTUnwrap(SubscriptionInformation(entitlement: entitlement))

        expect(subscriptionInfo.title).to(beNil())
        expect(subscriptionInfo.durationTitle).to(beNil())
        expect(subscriptionInfo.explanation) == .expired
        expect(subscriptionInfo.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(subscriptionInfo.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .expired
        expect(expirationOrRenewal.date) == .date("Apr 12, 2000")

        expect(subscriptionInfo.willRenew) == true
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.active) == false
        expect(subscriptionInfo.store) == .playStore
    }

}
