//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// CustomerCenterViewModelTests.swift
//
//
//  Created by Cesar de la Vega on 11/6/24.
//

// swiftlint:disable type_body_length function_body_length

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class CustomerCenterViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        expect(viewModel.state) == .notLoaded
        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .notLoaded
    }

    func testStateChangeToError() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        viewModel.state = .error(error)

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testIsLoaded() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        expect(viewModel.state) == .notLoaded

        viewModel.state = .success
        viewModel.configuration = CustomerCenterConfigTestData.customerCenterData

        expect(viewModel.state) == .success
    }

    func testLoadPurchaseInformationAlwaysRefreshesCustomerInfo() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(mockPurchases.customerInfoFetchPolicy) == .fetchCurrent
    }

    func testLoadAppleSubscriptions() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.store) == .appStore
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsGoogle() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithGoogleSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.store) == .playStore
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsNonActive() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithoutSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsFailure() async throws {
        let mockPurchases = MockCustomerCenterPurchases(customerInfoError: error)

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testShouldShowActiveSubscription_whenUserHasOneActiveSubscriptionOneEntitlement() async throws {
        // Arrange
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let products = [PurchaseInformationFixtures.product(id: productId,
                                                            title: "title",
                                                            duration: .month,
                                                            price: 2.99)]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )

        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: products
                                                ))

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title) == "title"
        expect(purchaseInformation.durationTitle) == "1 month"

        expect(purchaseInformation.price) == .paid("$2.99")

        let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: expirationDate))

        expect(purchaseInformation.productIdentifier) == productId
    }

    func testShouldShowActiveSubscription_whenUserHasOneActiveSubscriptionAndNoEntitlement() async throws {
        // Arrange
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let products = [PurchaseInformationFixtures.product(id: productId,
                                                            title: "title",
                                                            duration: .month,
                                                            price: 2.99)]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
            ]
        )

        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: products
                                                ))

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title) == "title"
        expect(purchaseInformation.durationTitle) == "1 month"

        expect(purchaseInformation.price) == .paid("$2.99")

        let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: expirationDate))

        expect(purchaseInformation.productIdentifier) == productId
    }

    func testShouldShowEarliestExpiringSubscription() async throws {
        // Arrange
        let yearlyProduct = (
            id: "com.revenuecat.yearly",
            exp: "2062-04-12T00:03:35Z", // Earlier expiration
            title: "yearly",
            duration: "1 year",
            price: Decimal(29.99)
        )
        let monthlyProduct = (
            id: "com.revenuecat.monthly",
            exp: "2062-05-12T00:03:35Z", // Later expiration
            title: "monthly",
            duration: "1 month",
            price: Decimal(2.99)
        )

        // Test both possible subscription array orders
        let subscriptionOrders = [
            [yearlyProduct, monthlyProduct],
            [monthlyProduct, yearlyProduct]
        ]

        for subscriptions in subscriptionOrders {
            let purchaseDate = "2022-04-12T00:03:28Z"
            let products = [
                PurchaseInformationFixtures.product(id: yearlyProduct.id,
                                                    title: yearlyProduct.title,
                                                    duration: .year,
                                                    price: yearlyProduct.price),
                PurchaseInformationFixtures.product(id: monthlyProduct.id,
                                                    title: monthlyProduct.title,
                                                    duration: .month,
                                                    price: monthlyProduct.price)
            ]

            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: subscriptions.map { product in
                    CustomerInfoFixtures.Subscription(
                        id: product.id,
                        store: "app_store",
                        purchaseDate: purchaseDate,
                        expirationDate: product.exp
                    )
                },
                entitlements: [
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: "premium",
                        productId: yearlyProduct.id,
                        purchaseDate: purchaseDate,
                        expirationDate: yearlyProduct.exp
                    )
                ]
            )

            let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
            // Should always show yearly subscription since it expires first
            expect(purchaseInformation.title) == yearlyProduct.title
            expect(purchaseInformation.durationTitle) == yearlyProduct.duration
            expect(purchaseInformation.price) == .paid(formatPrice(yearlyProduct.price))

            let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
            expect(expirationOrRenewal.label) == .nextBillingDate
            expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: yearlyProduct.exp))

            expect(purchaseInformation.productIdentifier) == yearlyProduct.id
        }
    }

    func testShouldShowClosestExpiring_whenUserHasLifetimeAndSubscriptions() async throws {
        let productIdLifetime = "com.revenuecat.simpleapp.lifetime"
        let productIdMonthly = "com.revenuecat.simpleapp.monthly"
        let productIdYearly = "com.revenuecat.simpleapp.yearly"
        let purchaseDateLifetime = "2024-11-21T16:04:20Z"
        let purchaseDateMonthly = "2024-11-21T16:04:39Z"
        let purchaseDateYearly = "2024-11-21T16:04:45Z"
        let expirationDateMonthly = "3024-11-28T16:04:39Z"
        let expirationDateYearly = "3025-11-21T16:04:45Z"

        let lifetimeProduct = PurchaseInformationFixtures.product(id: productIdLifetime,
                                                                  title: "lifetime",
                                                                  duration: nil,
                                                                  price: 29.99)
        let monthlyProduct = PurchaseInformationFixtures.product(id: productIdMonthly,
                                                                 title: "monthly",
                                                                 duration: .month,
                                                                 price: 2.99)
        let yearlyProduct = PurchaseInformationFixtures.product(id: productIdYearly,
                                                                title: "yearly",
                                                                duration: .year,
                                                                price: 29.99)

        let products = [lifetimeProduct, monthlyProduct, yearlyProduct]

        // Test both possible subscription array orders
        let subscriptionOrders = [
            [
                (id: productIdMonthly, date: purchaseDateMonthly, exp: expirationDateMonthly),
                (id: productIdYearly, date: purchaseDateYearly, exp: expirationDateYearly)
            ],
            [
                (id: productIdYearly, date: purchaseDateYearly, exp: expirationDateYearly),
                (id: productIdMonthly, date: purchaseDateMonthly, exp: expirationDateMonthly)
            ]
        ]

        for subscriptions in subscriptionOrders {
            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: subscriptions.map { subscription in
                    CustomerInfoFixtures.Subscription(
                        id: subscription.id,
                        store: "app_store",
                        purchaseDate: subscription.date,
                        expirationDate: subscription.exp
                    )
                },
                entitlements: [
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: "pro",
                        productId: productIdLifetime,
                        purchaseDate: purchaseDateLifetime,
                        expirationDate: nil
                    )
                ],
                nonSubscriptions: [
                    CustomerInfoFixtures.NonSubscriptionTransaction(
                        productId: productIdLifetime,
                        id: "2fdd18f128",
                        store: "app_store",
                        purchaseDate: purchaseDateLifetime
                    )
                ]
            )

            let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            await viewModel.loadScreen()

            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
            expect(purchaseInformation.title) == "monthly"
            expect(purchaseInformation.durationTitle) == "1 month"
            expect(purchaseInformation.price) == .paid("$2.99")
            expect(purchaseInformation.productIdentifier) == productIdMonthly

            expect(purchaseInformation.expirationOrRenewal?.date) == .date(reformat(ISO8601Date: expirationDateMonthly))
        }
    }

    func testShouldShowLifetime_whenUserHasLifetimeOneEntitlement() async throws {
        let productIdLifetime = "com.revenuecat.simpleapp.lifetime"
        let purchaseDateLifetime = "2024-11-21T16:04:20Z"

        let products = [
            PurchaseInformationFixtures.product(id: productIdLifetime,
                                                title: "lifetime",
                                                duration: nil,
                                                price: 29.99)
        ]

        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [],
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "pro",
                    productId: productIdLifetime,
                    purchaseDate: purchaseDateLifetime,
                    expirationDate: nil
                )
            ],
            nonSubscriptions: [
                CustomerInfoFixtures.NonSubscriptionTransaction(
                    productId: productIdLifetime,
                    id: "2fdd18f128",
                    store: "app_store",
                    purchaseDate: purchaseDateLifetime
                )
            ]
        )

        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: products
                                                ))

        await viewModel.loadScreen()

        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title) == "lifetime"
        expect(purchaseInformation.durationTitle).to(beNil())
        expect(purchaseInformation.price) == .paid("$29.99")
        expect(purchaseInformation.productIdentifier) == productIdLifetime

        expect(purchaseInformation.expirationOrRenewal?.date) == .never
    }

    func testShouldShowEarliestExpiration_whenUserHasTwoActiveSubscriptionsTwoEntitlements() async throws {
        // Arrange
        let yearlyProduct = (
            id: "com.revenuecat.product1",
            exp: "2062-04-12T00:03:35Z", // Earlier expiration
            title: "yearly",
            duration: "1 year",
            price: Decimal(29.99)
        )
        let monthlyProduct = (
            id: "com.revenuecat.product2",
            exp: "2062-05-12T00:03:35Z", // Later expiration
            title: "monthly",
            duration: "1 month",
            price: Decimal(2.99)
        )

        // Test both possible subscription and entitlement array orders
        let subscriptionOrders = [
            [yearlyProduct, monthlyProduct],
            [monthlyProduct, yearlyProduct]
        ]

        for subscriptions in subscriptionOrders {
            let purchaseDate = "2022-04-12T00:03:28Z"
            let products = [
                PurchaseInformationFixtures.product(id: yearlyProduct.id,
                                                    title: yearlyProduct.title,
                                                    duration: .year,
                                                    price: yearlyProduct.price),
                PurchaseInformationFixtures.product(id: monthlyProduct.id,
                                                    title: monthlyProduct.title,
                                                    duration: .month,
                                                    price: monthlyProduct.price)
            ]

            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: subscriptions.map { product in
                    CustomerInfoFixtures.Subscription(
                        id: product.id,
                        store: "app_store",
                        purchaseDate: purchaseDate,
                        expirationDate: product.exp
                    )
                },
                entitlements: subscriptions.map { product in
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: product.id == yearlyProduct.id ? "premium" : "plus",
                        productId: product.id,
                        purchaseDate: purchaseDate,
                        expirationDate: product.exp
                    )
                }
            )

            let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
            // Should always show yearly subscription since it expires first
            expect(purchaseInformation.title) == yearlyProduct.title
            expect(purchaseInformation.durationTitle) == yearlyProduct.duration
            expect(purchaseInformation.price) == .paid(formatPrice(yearlyProduct.price))

            let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
            expect(expirationOrRenewal.label) == .nextBillingDate
            expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: yearlyProduct.exp))

            expect(purchaseInformation.productIdentifier) == yearlyProduct.id
        }
    }

    func testShouldShowAppleSubscription_whenUserHasBothGoogleAndAppleSubscriptions() async throws {
        // Arrange
        let googleProduct = (
            id: "com.revenuecat.product1",
            store: "play_store",
            exp: "2062-04-12T00:03:35Z",
            title: "yearly",
            duration: "1 year",
            price: Decimal(29.99)
        )
        let appleProduct = (
            id: "com.revenuecat.product2",
            store: "app_store",
            exp: "2062-05-12T00:03:35Z",
            title: "monthly",
            duration: "1 month",
            price: Decimal(2.99)
        )

        // Test both possible subscription and entitlement array orders
        let subscriptionOrders = [
            [googleProduct, appleProduct],
            [appleProduct, googleProduct]
        ]

        for subscriptions in subscriptionOrders {
            let purchaseDate = "2022-04-12T00:03:28Z"
            let products = [
                PurchaseInformationFixtures.product(id: googleProduct.id,
                                                    title: googleProduct.title,
                                                    duration: .year,
                                                    price: googleProduct.price),
                PurchaseInformationFixtures.product(id: appleProduct.id,
                                                    title: appleProduct.title,
                                                    duration: .month,
                                                    price: appleProduct.price)
            ]

            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: subscriptions.map { product in
                    CustomerInfoFixtures.Subscription(
                        id: product.id,
                        store: product.store,
                        purchaseDate: purchaseDate,
                        expirationDate: product.exp
                    )
                },
                entitlements: subscriptions.map { product in
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: product.id == googleProduct.id ? "premium" : "plus",
                        productId: product.id,
                        purchaseDate: purchaseDate,
                        expirationDate: product.exp
                    )
                }
            )

            let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
            // We expect to see the monthly one, because the yearly one is a Google subscription
            expect(purchaseInformation.title) == appleProduct.title
            expect(purchaseInformation.durationTitle) == appleProduct.duration
            expect(purchaseInformation.price) == .paid(formatPrice(appleProduct.price))

            let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
            expect(expirationOrRenewal.label) == .nextBillingDate
            expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: appleProduct.exp))

            expect(purchaseInformation.productIdentifier) == appleProduct.id
        }
    }

    func testShouldShowActiveSubscription_withoutProductInformation() async throws {
        // If product can't load because maybe it's from another app in same project

        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"

        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )

        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: []
                                                ))

        await viewModel.loadScreen()

        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title).to(beNil())
        expect(purchaseInformation.durationTitle).to(beNil())
        expect(purchaseInformation.explanation) == .earliestRenewal
        expect(purchaseInformation.store) == .appStore
        expect(purchaseInformation.price) == .unknown

        let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: expirationDate))

        expect(purchaseInformation.productIdentifier) == productId
    }

    func testLoadScreenNoActiveSubscription() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: mockPurchases)

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .success
    }

    func testLoadScreenFailure() async throws {
        let mockPurchases = MockCustomerCenterPurchases(customerInfoError: error)
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                purchasesProvider: mockPurchases)

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .error(error)
    }

    func testAppIsLatestVersion() {
        let testCases = [
            (currentVersion: "1.0.0", latestVersion: "2.0.0", expectedAppIsLatestVersion: false),
            (currentVersion: "2.0.0", latestVersion: "2.0.0", expectedAppIsLatestVersion: true),
            (currentVersion: "3.0.0", latestVersion: "2.0.0", expectedAppIsLatestVersion: true),
            (currentVersion: "1.0.0", latestVersion: "1.1.0", expectedAppIsLatestVersion: false),
            (currentVersion: "1.1.0", latestVersion: "1.1.0", expectedAppIsLatestVersion: true),
            (currentVersion: "1.1.0", latestVersion: "1.0.0", expectedAppIsLatestVersion: true),
            (currentVersion: "1.0.0", latestVersion: "1.0.1", expectedAppIsLatestVersion: false),
            (currentVersion: "1.0.1", latestVersion: "1.0.1", expectedAppIsLatestVersion: true),
            (currentVersion: "1.0.1", latestVersion: "1.0.0", expectedAppIsLatestVersion: true),
            // The CFBundleVersion docs state:
            // > You can include more integers but the system ignores them.
            // https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleversion
            // So we should do the same.
            (currentVersion: "2.0.0.2.3.4", latestVersion: "2.0.0.3.4.5", expectedAppIsLatestVersion: true),
            (currentVersion: "1.0.0.2.3.4", latestVersion: "2.0.0.3.4.5", expectedAppIsLatestVersion: false),
            (currentVersion: "1.2", latestVersion: "2", expectedAppIsLatestVersion: false),
            (currentVersion: "1.2", latestVersion: "1", expectedAppIsLatestVersion: true),
            (currentVersion: "2", latestVersion: "1", expectedAppIsLatestVersion: true),
            (currentVersion: "0", latestVersion: "1", expectedAppIsLatestVersion: false),
            (currentVersion: "10.2", latestVersion: "2", expectedAppIsLatestVersion: true),
            // We default to true if we fail to parse any of the two versions.
            (currentVersion: "not-a-number", latestVersion: "not-a-number-either", expectedAppIsLatestVersion: true),
            (currentVersion: "not-a-number", latestVersion: "1.2.3", expectedAppIsLatestVersion: true),
            (currentVersion: "1.2.3", latestVersion: "not-a-number", expectedAppIsLatestVersion: true),
            (currentVersion: "not.a.number", latestVersion: "1.2.3", expectedAppIsLatestVersion: true),
            (currentVersion: "1.2.3", latestVersion: "not.a.number", expectedAppIsLatestVersion: true),
            (currentVersion: nil, latestVersion: nil, expectedAppIsLatestVersion: true),
            (currentVersion: "1.2.3", latestVersion: nil, expectedAppIsLatestVersion: true),
            (currentVersion: nil, latestVersion: "1.2.3", expectedAppIsLatestVersion: true),
            (currentVersion: "", latestVersion: "", expectedAppIsLatestVersion: true),
            (currentVersion: "1.2.3", latestVersion: "", expectedAppIsLatestVersion: true),
            (currentVersion: "", latestVersion: "1.2.3", expectedAppIsLatestVersion: true)
        ]
        for (currentVersion, latestVersion, expectedAppIsLatestVersion) in testCases {
            XCTContext.runActivity(
                named: "Current version = \(currentVersion as Optional), " +
                "latest version = \(latestVersion as Optional), " +
                "expectedAppIsLatestVersion = \(expectedAppIsLatestVersion)"
            ) { _ in
                let viewModel = CustomerCenterViewModel(
                    customerCenterActionHandler: nil,
                    currentVersionFetcher: { return currentVersion }
                )
                viewModel.state = .success
                viewModel.configuration = CustomerCenterConfigTestData.customerCenterData(
                    lastPublishedAppVersion: latestVersion
                )

                expect(viewModel.appIsLatestVersion) == expectedAppIsLatestVersion
            }
        }
    }

    func testTrackImpression() throws {
        let mockPurchases = MockCustomerCenterPurchases()
        mockPurchases.isSandbox = true
        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            purchasesProvider: mockPurchases
        )

        let darkMode = true
        let displayMode: CustomerCenterPresentationMode = .fullScreen

        viewModel.trackImpression(darkMode: darkMode, displayMode: displayMode)

        expect(mockPurchases.trackedEvents.count) == 1
        let trackedEvent = try XCTUnwrap(mockPurchases.trackedEvents.first as? CustomerCenterEvent)

        expect(trackedEvent.data.darkMode) == darkMode
        expect(trackedEvent.data.displayMode) == displayMode
        expect(trackedEvent.data.localeIdentifier) == Locale.current.identifier
        expect(trackedEvent.data.isSandbox) == true
        if case .impression = trackedEvent {} else {
            fail("Expected an impression event")
        }

        viewModel.trackImpression(darkMode: darkMode, displayMode: displayMode)
        viewModel.trackImpression(darkMode: darkMode, displayMode: displayMode)
        viewModel.trackImpression(darkMode: darkMode, displayMode: displayMode)
        expect(mockPurchases.trackedEvents.count) == 1
    }

    func testShouldShowAppUpdateWarningsTrue() {
        let mockPurchases = MockCustomerCenterPurchases()
        let latestVersion = "3.0.0"
        let currentVersion = "2.0.0"
        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            currentVersionFetcher: { return currentVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigTestData.customerCenterData(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: true
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beTrue())
    }

    func testShouldShowAppUpdateWarningsFalse() {
        let mockPurchases = MockCustomerCenterPurchases()
        let latestVersion = "3.0.0"
        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            currentVersionFetcher: { return latestVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigTestData.customerCenterData(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: true
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beFalse())
    }

    func testShouldShowAppUpdateWarningsFalseIfBlockedByConfig() {
        let mockPurchases = MockCustomerCenterPurchases()
        let latestVersion = "3.0.0"
        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            currentVersionFetcher: { return latestVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigTestData.customerCenterData(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: false
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beFalse())
    }

    func testPurchaseInformationIsStillLoadedIfRenewalInfoCantBeFetched() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let mockStoreKitUtilities = MockCustomerCenterStoreKitUtilities()

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            currentVersionFetcher: { return "3.0.0" },
            purchasesProvider: mockPurchases,
            customerCenterStoreKitUtilities: mockStoreKitUtilities as CustomerCenterStoreKitUtilitiesType
        )

        expect(mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo).to(beNil())

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).toNot(beNil())
        expect(mockStoreKitUtilities.renewalPriceFromRenewalInfoCallCount).to(equal(1))
    }

    func testPurchaseInformationUsesInfoFromRenewalInfoWhenAvailable() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let mockStoreKitUtilities = MockCustomerCenterStoreKitUtilities()
        mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo = (5, "USD")

        let viewModel = CustomerCenterViewModel(
            customerCenterActionHandler: nil,
            currentVersionFetcher: { return "3.0.0" },
            purchasesProvider: mockPurchases,
            customerCenterStoreKitUtilities: mockStoreKitUtilities as CustomerCenterStoreKitUtilitiesType
        )

        expect(mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo).to(equal((5, "USD")))

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation?.price).to(equal(.paid("$5.00")))
        expect(mockStoreKitUtilities.renewalPriceFromRenewalInfoCallCount).to(equal(1))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterViewModelTests {

    static let customerInfoWithAppleSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2062-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "2022-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithGoogleSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "play_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2062-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "2022-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithoutSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2000-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "1999-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "1999-04-12T00:03:28Z",
                        "store": "play_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2000-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "1999-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

    func reformat(ISO8601Date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: ISO8601DateFormatter().date(from: ISO8601Date)!)
    }

    func formatPrice(_ price: Decimal) -> String {
        "$\(String(format: "%.2f", NSDecimalNumber(decimal: price).doubleValue))"
    }

}

#endif
