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
import XCTest

import RevenueCat
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
            isSubscrition: false
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                subscribedProduct: mockProduct.toStoreProduct(),
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: mockCustomerCenterStoreKitUtilities,
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice) == .nonFree("$7.99")
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)

        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beTrue())

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
            isSubscrition: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfoNullable = await PurchaseInformation.purchaseInformationUsingRenewalInfo(
            entitlement: entitlement,
            subscribedProduct: mockProduct.toStoreProduct(),
            transaction: mockTransaction,
            customerCenterStoreKitUtilities: MockCustomerCenterStoreKitUtilities(mockRenewalPrice: nil),
            customerInfoRequestedDate: Date(),
            dateFormatter: Self.mockDateFormatter,
            numberFormatter: Self.mockNumberFormatter,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )

        let subscriptionInfo = try XCTUnwrap(subscriptionInfoNullable)
        expect(subscriptionInfo.title) == "Monthly Product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$6.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        // title from entitlement instead of product identifier
        expect(subscriptionInfo.title) == "premium"
        expect(subscriptionInfo.pricePaid) == .free
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "premium"
        expect(subscriptionInfo.pricePaid) == .free
        expect(subscriptionInfo.renewalPrice).to(beNil())
        // false - no way to know if its lifetime
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice) == .nonFree("$1.99")
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: entitlement,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )

        expect(subscriptionInfo.title) == "com.revenuecat.product"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.renewalPrice).to(beNil())
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

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
            isSubscrition: true
        )

        let subscriptionInfo = try XCTUnwrap(
            PurchaseInformation(
                entitlement: nil,
                subscribedProduct: nil,
                transaction: mockTransaction,
                customerInfoRequestedDate: Date(),
                dateFormatter: Self.mockDateFormatter,
                numberFormatter: Self.mockNumberFormatter,
                managementURL: URL(string: "https://www.revenuecat.com")!
            )
        )
        expect(subscriptionInfo.title) == "product_id"
        expect(subscriptionInfo.pricePaid) == .nonFree("$1.99")
        expect(subscriptionInfo.isLifetimeSubscription).to(beFalse())

        expect(subscriptionInfo.productIdentifier) == "product_id"
        expect(subscriptionInfo.store) == .stripe
    }

}
