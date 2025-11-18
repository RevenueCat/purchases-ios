//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformationTests.swift
//
//  Created by Cesar de la Vega on 10/25/24.

import Nimble
import StoreKit
import XCTest

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI

// swiftlint:disable file_length type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseInformationTests: TestCase {

    static let locale: Locale = .current
    static let mockDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "UTC")!
        return formatter
    }()

    static let mockNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        return formatter
    }()

    static let mockLocalization = CustomerCenterConfigData.Localization(
        locale: "en_US",
        localizedStrings: [:]
    )

    private class MockCustomerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType {
        var mockRenewalPrice: (price: Decimal, currencyCode: String)?

        init(mockRenewalPrice: (price: Decimal, currencyCode: String)? = (7.99, "USD")) {
            self.mockRenewalPrice = mockRenewalPrice
        }

        func renewalPriceFromRenewalInfo(for product: RevenueCat.StoreProduct) async ->
        (price: Decimal, currencyCode: String)? {
            return mockRenewalPrice
        }
    }

    private let mockCustomerCenterStoreKitUtilities = MockCustomerCenterStoreKitUtilities()

    func testAppleEntitlementAndSubscribedProductWithoutRenewalInfo() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions
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

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: false
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                subscribedProduct: mockProduct.toStoreProduct(),
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: CustomerCenterConfigData.ChangePlan(
                    groupId: "groupId",
                    groupName: "groupName",
                    products: []
                ),
                localization: Self.mockLocalization
            )
        )
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())
        expect(subscriptionInfo.changePlan).toNot(beNil())
        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndSubscribedProductWithRenewalInfo() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions
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

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: mockCustomerCenterStoreKitUtilities,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            changePlan: nil,
            localization: Self.mockLocalization
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice) == .nonFree("$7.99")
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndLifetimeProduct() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithLifetimeAppSubscrition
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

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: nil,
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            changePlan: nil,
            localization: Self.mockLocalization
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)

        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndNonRenewingSubscribedProduct() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithNonRenewingAppleSubscriptions
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

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            changePlan: nil,
            localization: Self.mockLocalization
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .appStore
    }

    func testAppleEntitlementAndExpiredSubscribedProduct() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
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

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            changePlan: nil,
            localization: Self.mockLocalization
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .appStore
    }

    func testInitWithGoogleEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .playStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithGoogleEntitlementNonRenewing() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithNonRenewingGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .playStore,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithGoogleEntitlementExpired() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .playStore,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 6.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .playStore
    }

    func testInitWithPromotionalEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithPromotional
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .promotional,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        // title from entitlement instead of product identifier
        expect(subscriptionInfo.title) == "One-time Purchase"
        expect(subscriptionInfo.pricePaid) == .free
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .promotional
    }

    func testInitWithPromotionalLifetimeEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .promotional,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: nil,
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "One-time Purchase"
        expect(subscriptionInfo.pricePaid) == .free
        expect(subscriptionInfo.renewalPrice).to(beNil())
        // false - no way to know if its lifetime
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .promotional
    }

    func testInitWithStripeEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .stripe,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .stripe
    }

    func testInitWithStripeEntitlementNonRenewing() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithNonRenewingStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .stripe,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .stripe
    }

    func testInitWithStripeEntitlementExpired() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredStripeSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .stripe,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .stripe
    }

    func testInitWithRCBillingEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithRCBillingSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .rcBilling,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .rcBilling
    }

    func testInitWithRCBillingEntitlementNonRenewing() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithNonRenewingRCBillingSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .rcBilling,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .rcBilling
    }

    func testInitWithRCBillingEntitlementExpired() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredRCBillingSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .rcBilling,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .rcBilling
    }

    func testInitWithPaddleEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithPaddleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .paddle,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .paddle
    }

    func testInitWithPaddleEntitlementNonRenewing() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithNonRenewingPaddleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .paddle,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .paddle
    }

    func testInitWithPaddleEntitlementExpired() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredPaddleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .paddle,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .paddle
    }

    func testLoadingOnlyWithOnlyPurchaseInformation() throws {
        let mockTransaction = MockTransaction(
            productIdentifier: "product_id",
            store: .stripe,
            type: .subscription(
                isActive: false,
                willRenew: false,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2000"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: nil,
                subscribedProduct: nil,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                localization: Self.mockLocalization
            )
        )
        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == "product_id"
        expect(subscriptionInfo.store) == .stripe
    }

    func testInitWithSimulatedStoreEntitlement() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithSimulatedStoreSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .paddle,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: PurchaseOwnershipType.unknown
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 1.99),
            displayName: "A product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!,
                changePlan: nil,
                localization: Self.mockLocalization
            )
        )

        expect(subscriptionInfo.title) == "Subscription"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetime).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == entitlement.productIdentifier
        expect(subscriptionInfo.store) == .testStore
    }

    // MARK: - Tests for improved title and price determination logic

    func testDetermineTitleWithEntitlementIdentifierFallback() throws {
        // Use existing Google Play fixture which has entitlement identifier "premium"
        let customerInfo = CustomerInfoFixtures.customerInfoWithGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .playStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 9.99),
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: entitlement,
            subscribedProduct: nil, // No StoreKit product available
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should use purchase type as title when no StoreKit product is available (matching Android)
        expect(purchaseInfo.title) == "Subscription"
    }

    func testDetermineTitleWithStoreKitProductTitle() throws {
        // Use existing Apple subscription fixture
        let customerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let mockProduct = TestStoreProduct(
            localizedTitle: "Premium Monthly Subscription",
            price: 9.99,
            localizedPriceString: "$9.99",
            productIdentifier: entitlement.productIdentifier,
            productType: .autoRenewableSubscription,
            localizedDescription: "Premium features monthly",
            subscriptionGroupIdentifier: "premium_group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 9.99),
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should prefer StoreKit product title over entitlement identifier
        expect(purchaseInfo.title) == "Premium Monthly Subscription"
    }

    func testDeterminePricePaidWithTransactionPricePriority() throws {
        let mockProduct = TestStoreProduct(
            localizedTitle: "Premium Product",
            price: 19.99, // Different from transaction price
            localizedPriceString: "$19.99",
            productIdentifier: "com.app.premium",
            productType: .autoRenewableSubscription,
            localizedDescription: "Premium features",
            subscriptionGroupIdentifier: "premium_group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let mockTransaction = MockTransaction(
            productIdentifier: "com.app.premium",
            store: .stripe,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 9.99), // Actual paid price
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should use transaction price (what was actually paid) over product price
        expect(purchaseInfo.pricePaid) == .nonFree("$9.99")
    }

    func testDeterminePricePaidWithZeroTransactionPrice() throws {
        let mockTransaction = MockTransaction(
            productIdentifier: "com.app.premium",
            store: .playStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 0.00), // Free transaction
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: nil,
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should return free for zero amount transactions
        expect(purchaseInfo.pricePaid) == .free
    }

    func testDeterminePricePaidWithSandboxZeroPrice() throws {
        let mockTransaction = MockTransaction(
            productIdentifier: "com.app.premium",
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 0.00),
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: true, // Sandbox purchase
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: nil,
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should return free for sandbox purchases with zero price
        expect(purchaseInfo.pricePaid) == .free
    }

    func testDeterminePricePaidUnknownWhenTransactionPriceUnavailable() throws {
        let mockProduct = TestStoreProduct(
            localizedTitle: "Premium Product",
            price: 14.99,
            localizedPriceString: "$14.99",
            productIdentifier: "com.app.premium",
            productType: .autoRenewableSubscription,
            localizedDescription: "Premium features",
            subscriptionGroupIdentifier: "premium_group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: nil,
            locale: Self.locale
        )

        let mockTransaction = MockTransaction(
            productIdentifier: "com.app.premium",
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: nil, // No transaction price available
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        expect(purchaseInfo.pricePaid) == .unknown
    }

    func testDeterminePricePaidUnknownWhenNoPriceAvailable() throws {
        let mockTransaction = MockTransaction(
            productIdentifier: "com.app.premium",
            store: .external,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: nil, // No transaction price
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: nil, // No product price either
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Should return unknown when no price information is available
        expect(purchaseInfo.pricePaid) == .unknown
    }

    func testPromotionalPurchaseAlwaysFree() throws {
        let mockTransaction = MockTransaction(
            productIdentifier: "rc_promo_premium",
            store: .promotional,
            type: .subscription(
                isActive: true,
                willRenew: false,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 9.99), // Even with price, should be free
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: nil,
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        // Promotional store purchases should always be free regardless of price
        expect(purchaseInfo.pricePaid) == .free
    }

    func testPurchaseTypeLocalization() throws {
        // Test subscription type
        let customerInfo = CustomerInfoFixtures.customerInfoWithGoogleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let subscriptionTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .playStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 9.99),
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = PurchaseInformation(
            entitlement: entitlement,
            subscribedProduct: nil,
            transaction: subscriptionTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        expect(subscriptionInfo.isSubscription) == true

        // Test one-time purchase type
        let oneTimeTransaction = MockTransaction(
            productIdentifier: "com.app.consumable",
            store: .appStore,
            type: .nonSubscription,
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 4.99),
            displayName: nil,
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: false
        )

        let oneTimeInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: nil,
            transaction: oneTimeTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        expect(oneTimeInfo.isSubscription) == false
        expect(oneTimeInfo.title) == "One-time Purchase"
    }

    func testSK1SubscriptionIsNotLifetime() throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all.first?.value)

        let sk1Product = TestSK1Product(
            productIdentifier: entitlement.productIdentifier,
            price: 9.99,
            priceLocale: Locale(identifier: "en_US"),
            subscriptionPeriod: SKProductSubscriptionPeriod()
        )
        let mockProduct = StoreProduct(sk1Product: sk1Product)

        let mockTransaction = MockTransaction(
            productIdentifier: entitlement.productIdentifier,
            store: .appStore,
            type: .subscription(
                isActive: true,
                willRenew: true,
                expiresDate: Self.mockDateFormatter.date(from: "Apr 12, 2062"),
                isTrial: false,
                ownershipType: .purchased
            ),
            isCancelled: false,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            price: .init(currency: "USD", amount: 9.99),
            displayName: "Monthly subscription",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: true
        )

        let subscriptionInfo = PurchaseInformation(
            entitlement: entitlement,
            subscribedProduct: mockProduct,
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            localization: Self.mockLocalization
        )

        expect(subscriptionInfo.isLifetime).to(beFalse())
        expect(subscriptionInfo.isSubscription) == true
        expect(subscriptionInfo.productType) == StoreProduct.ProductType.nonConsumable
        expect(mockProduct.sk1Product).toNot(beNil())
    }

    func testSK1NonConsumableIsNotLifetime() throws {
        let sk1Product = TestSK1Product(
            productIdentifier: "lifetime_product",
            price: 49.99,
            priceLocale: Locale(identifier: "en_US"),
            subscriptionPeriod: nil
        )
        let mockProduct = StoreProduct(sk1Product: sk1Product)

        let mockTransaction = MockTransaction(
            productIdentifier: "lifetime_product",
            store: .appStore,
            type: .nonSubscription,
            isCancelled: false,
            managementURL: nil,
            price: .init(currency: "USD", amount: 49.99),
            displayName: "Lifetime product",
            periodType: .normal,
            purchaseDate: Date(),
            isSandbox: false,
            isSubscription: false
        )

        let purchaseInfo = PurchaseInformation(
            entitlement: nil,
            subscribedProduct: mockProduct,
            transaction: mockTransaction,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: nil,
            localization: Self.mockLocalization
        )

        expect(purchaseInfo.isLifetime).to(beFalse())
        expect(purchaseInfo.isSubscription) == false
        expect(purchaseInfo.productType) == StoreProduct.ProductType.nonConsumable
        expect(mockProduct.sk1Product).toNot(beNil())
    }

}

private class TestSK1Product: SKProduct, @unchecked Sendable {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    private let _subscriptionPeriod: SKProductSubscriptionPeriod?

    init(productIdentifier: String,
         price: Decimal = 0.99,
         priceLocale: Locale = Locale(identifier: "en_US"),
         subscriptionPeriod: SKProductSubscriptionPeriod? = nil) {
        self._productIdentifier = productIdentifier
        self._price = price as NSDecimalNumber
        self._priceLocale = priceLocale
        self._subscriptionPeriod = subscriptionPeriod
        super.init()
    }

    override var productIdentifier: String { _productIdentifier }
    override var price: NSDecimalNumber { _price }
    override var priceLocale: Locale { _priceLocale }
    
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    override var subscriptionPeriod: SKProductSubscriptionPeriod? { _subscriptionPeriod }
}
