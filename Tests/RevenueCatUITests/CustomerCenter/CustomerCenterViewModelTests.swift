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
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS)

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class CustomerCenterViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper())

        expect(viewModel.state) == .notLoaded
        expect(viewModel.hasPurchases).to(beFalse())
        expect(viewModel.subscriptionsSection).to(beEmpty())
        expect(viewModel.nonSubscriptionsSection).to(beEmpty())
        expect(viewModel.state) == .notLoaded
        expect(viewModel.virtualCurrencies).to(beNil())
    }

    func testStateChangeToError() {
        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper())

        viewModel.state = .error(error)

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }

        expect(viewModel.subscriptionsSection).to(beEmpty())
    }

    func testIsLoaded() {
        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper())

        expect(viewModel.state) == .notLoaded

        viewModel.state = .success
        viewModel.configuration = CustomerCenterConfigData.default

        expect(viewModel.state) == .success
    }

    func testLoadPurchaseInformationAlwaysRefreshesCustomerInfo() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(mockPurchases.customerInfoFetchPolicy) == .fetchCurrent
    }

    func testLoadAppleSubscriptions() async throws {
        let product = PurchaseInformationFixtures.product(
            id: "com.revenuecat.product",
            title: "title",
            duration: .month,
            price: 2.99
        )

        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions,
            products: [product]
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.subscriptionsSection.count) == 1

        let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
        expect(purchaseInformation.productIdentifier) == product.productIdentifier
        expect(viewModel.nonSubscriptionsSection).to(beEmpty())

        expect(purchaseInformation.store) == .appStore
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsGoogle() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithGoogleSubscription(
                requestDate: Date().addingTimeInterval(-60*60),
                entitlementExpiryDate: Date(),
                subscriptionExpiryDate: Date()
            )
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.hasPurchases).to(beTrue())
        let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
        expect(purchaseInformation.productIdentifier) == "test_msmath_premium_v1"

        expect(viewModel.nonSubscriptionsSection).to(beEmpty())
        expect(purchaseInformation.store) == .playStore
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsNonActive() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithoutSubscriptions
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.hasPurchases).to(beFalse())
        expect(viewModel.subscriptionsSection).to(beEmpty())
        expect(viewModel.nonSubscriptionsSection).to(beEmpty())

        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsFailure() async throws {
        let mockPurchases = MockCustomerCenterPurchases(customerInfoError: error)

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.subscriptionsSection).to(beEmpty())
        expect(viewModel.nonSubscriptionsSection).to(beEmpty())

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testLoadLoadsVirtualCurrenciesWhenDisplayVirtualCurrenciesIsTrue() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            customerCenterConfigData: CustomerCenterConfigData.mock(displayVirtualCurrencies: true)
        )
        mockPurchases.virtualCurrenciesResult = .success(VirtualCurrenciesFixtures.fourVirtualCurrencies)

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()
        expect(viewModel.virtualCurrencies).toNot(beNil())
        guard let virtualCurrencies = viewModel.virtualCurrencies else {
            fail("Virtual currencies should not be nil")
            return
        }

        expect(virtualCurrencies.all.count).to(equal(4))
        expect(virtualCurrencies["GLD"]).toNot(beNil())
        expect(virtualCurrencies["SLV"]).toNot(beNil())
        expect(virtualCurrencies["BRNZ"]).toNot(beNil())
        expect(virtualCurrencies["PLTNM"]).toNot(beNil())
        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(1))
        expect(mockPurchases.invalidateVirtualCurrenciesCacheCallCount).to(equal(1))
    }

    func testLoadDoesNotLoadVirtualCurrenciesWhenDisplayVirtualCurrenciesIsFalse() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            customerCenterConfigData: CustomerCenterConfigData.mock(displayVirtualCurrencies: false)
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()
        expect(viewModel.virtualCurrencies).to(beNil())
        expect(mockPurchases.virtualCurrenciesCallCount).to(equal(0))
    }

    func testShouldShowVirtualCurrenciesIsFalseBeforeConfigIsLoaded() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            customerCenterConfigData: CustomerCenterConfigData.mock(displayVirtualCurrencies: true)
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        expect(viewModel.shouldShowVirtualCurrencies).to(beFalse())
    }

    func testShouldShowVirtualCurrenciesTrue() async throws {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            customerCenterConfigData: CustomerCenterConfigData.mock(displayVirtualCurrencies: true)
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        await viewModel.loadScreen()

        expect(viewModel.shouldShowVirtualCurrencies).to(beTrue())
    }

    func testShouldShowVirtualCurrenciesFalse() {
        let mockPurchases = MockCustomerCenterPurchases(
            customerInfo: CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
            customerCenterConfigData: CustomerCenterConfigData.mock(displayVirtualCurrencies: false)
        )

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: mockPurchases
        )

        expect(viewModel.shouldShowVirtualCurrencies).to(beFalse())
    }

    func testShouldShowActiveSubscription_whenUserHasOneActiveSubscriptionOneEntitlement() async throws {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let products = [
            PurchaseInformationFixtures.product(
                id: productId,
                title: "title",
                duration: .month,
                price: 2.99
            )
        ]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    priceAmount: 4.99
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

        let viewModelWithoutRenewal = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: MockCustomerCenterPurchases(
                customerInfo: customerInfo,
                products: products
            )
        )

        let mockRenewal = MockCustomerCenterStoreKitUtilities()
        mockRenewal.returnRenewalPriceFromRenewalInfo = (2.99, "USD")

        let viewModelWithRenewal = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: MockCustomerCenterPurchases(
                customerInfo: customerInfo,
                products: products
            ),
            customerCenterStoreKitUtilities: mockRenewal
        )

        try await checkExpectations(viewModelWithoutRenewal, renewalPrice: nil)
        try await checkExpectations(
            viewModelWithRenewal,
            renewalPrice: .nonFree(formatted(price: 2.99, currencyCode: "USD"))
        )

        func checkExpectations(
            _ viewModel: CustomerCenterViewModel,
            renewalPrice: PurchaseInformation.RenewalPrice?
        ) async throws {
            await viewModel.loadScreen()

            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
            expect(viewModel.subscriptionsSection.count) == 1
            expect(viewModel.subscriptionsSection.first?.productIdentifier)
                == purchaseInformation.productIdentifier

            expect(purchaseInformation.title) == "title"

            expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 4.99))
            if let renewalPrice {
                expect(purchaseInformation.renewalPrice) == renewalPrice
            } else {
                expect(purchaseInformation.renewalPrice).to(beNil()) // no renewal info
            }

            expect(purchaseInformation.productIdentifier) == productId
        }
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

        let currency = "USD"
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    priceAmount: 3.99,
                    currency: currency
                )
            ],
            entitlements: []
        )

        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: products
                                                ))

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
        expect(viewModel.subscriptionsSection.count) == 1
        expect(viewModel.subscriptionsSection.first?.productIdentifier) == purchaseInformation.productIdentifier

        expect(purchaseInformation.title) == "title"
        expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 3.99, currencyCode: currency))
        expect(purchaseInformation.renewalPrice).to(beNil())

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
                        expirationDate: product.exp,
                        priceAmount: product.price
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

            let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
            expect(viewModel.subscriptionsSection.count) == 2
            expect(viewModel.subscriptionsSection.first?.productIdentifier)
                == purchaseInformation.productIdentifier

            // Should always show yearly subscription since it expires first
            expect(purchaseInformation.title) == yearlyProduct.title

            expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 29.99))

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
                        expirationDate: subscription.exp,
                        priceAmount: 1.99
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

            let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            await viewModel.loadScreen()

            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
            expect(viewModel.subscriptionsSection.count) == 2
            expect(viewModel.subscriptionsSection.first?.productIdentifier)
                == purchaseInformation.productIdentifier

            expect(purchaseInformation.title) == "monthly"
            expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 1.99, currencyCode: "USD"))
            expect(purchaseInformation.renewalPrice).to(beNil())

            expect(purchaseInformation.productIdentifier) == productIdMonthly
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

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            purchasesProvider: MockCustomerCenterPurchases(
                customerInfo: customerInfo,
                products: products
            )
        )

        await viewModel.loadScreen()

        expect(viewModel.state) == .success

        expect(viewModel.subscriptionsSection.count) == 0
        let purchaseInformation = try XCTUnwrap(viewModel.nonSubscriptionsSection.first)
        expect(viewModel.nonSubscriptionsSection.count) == 1

        expect(purchaseInformation.title) == "lifetime"
        expect(purchaseInformation.pricePaid) == .unknown // no info about non-subscriptions in customer info
        expect(purchaseInformation.productIdentifier) == productIdLifetime
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
                        expirationDate: product.exp,
                        priceAmount: product.price
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

            let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
            expect(viewModel.subscriptionsSection.count) == 2
            expect(viewModel.subscriptionsSection.first?.productIdentifier)
                == purchaseInformation.productIdentifier

            // Should always show yearly subscription since it expires first
            expect(purchaseInformation.title) == yearlyProduct.title
            expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 29.99))

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
                        expirationDate: product.exp,
                        priceAmount: product.price
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

            let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                    purchasesProvider: MockCustomerCenterPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                    ))

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.last)

            expect(viewModel.subscriptionsSection.count) == 2
            expect(viewModel.subscriptionsSection.last?.productIdentifier)
                == purchaseInformation.productIdentifier

            // We expect to see the monthly one, because the yearly one is a Google subscription
            expect(purchaseInformation.title) == appleProduct.title
            expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: appleProduct.price))

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
                    expirationDate: expirationDate,
                    priceAmount: 1.99
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

        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                purchasesProvider: MockCustomerCenterPurchases(
                                                    customerInfo: customerInfo,
                                                    products: []
                                                ))

        await viewModel.loadScreen()

        expect(viewModel.state) == .success
        expect(viewModel.shouldShowList).to(beFalse())

        let purchaseInformation = try XCTUnwrap(viewModel.subscriptionsSection.first)
        expect(viewModel.subscriptionsSection.count) == 1
        expect(viewModel.subscriptionsSection.first?.productIdentifier) == purchaseInformation.productIdentifier

        expect(purchaseInformation.title) == "com.revenuecat.product" // product identifier
        expect(purchaseInformation.store) == .appStore
        expect(purchaseInformation.pricePaid) == .nonFree(formatted(price: 1.99)) // from transaction

        expect(purchaseInformation.productIdentifier) == productId
    }

    func testLoadScreenNoActiveSubscription() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                purchasesProvider: mockPurchases)

        await viewModel.loadScreen()

        expect(viewModel.subscriptionsSection.first).to(beNil())
        expect(viewModel.state) == .success
        expect(viewModel.shouldShowList).to(beFalse())
    }

    func testLoadScreenFailure() async throws {
        let mockPurchases = MockCustomerCenterPurchases(customerInfoError: error)
        let viewModel = CustomerCenterViewModel(actionWrapper: CustomerCenterActionWrapper(),
                                                purchasesProvider: mockPurchases)

        await viewModel.loadScreen()

        expect(viewModel.subscriptionsSection.first).to(beNil())
        expect(viewModel.subscriptionsSection).to(beEmpty())
        expect(viewModel.shouldShowList).to(beFalse())
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
                    actionWrapper: CustomerCenterActionWrapper(),
                    currentVersionFetcher: { return currentVersion }
                )
                viewModel.state = .success
                viewModel.configuration = CustomerCenterConfigData.mock(
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
            actionWrapper: CustomerCenterActionWrapper(),
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
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return currentVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigData.mock(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: true
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beTrue())
    }

    func testShouldShowAppUpdateWarningsFalse() {
        let mockPurchases = MockCustomerCenterPurchases()
        let latestVersion = "3.0.0"
        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return latestVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigData.mock(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: true
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beFalse())
    }

    func testShouldShowAppUpdateWarningsFalseIfBlockedByConfig() {
        let mockPurchases = MockCustomerCenterPurchases()
        let latestVersion = "3.0.0"
        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return latestVersion },
            purchasesProvider: mockPurchases
        )
        viewModel.configuration = CustomerCenterConfigData.mock(
            lastPublishedAppVersion: latestVersion,
            shouldWarnCustomerToUpdate: false
        )

        expect(viewModel.shouldShowAppUpdateWarnings).to(beFalse())
    }

    func testPurchaseInformationIsStillLoadedIfRenewalInfoCantBeFetched() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let mockStoreKitUtilities = MockCustomerCenterStoreKitUtilities()

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return "3.0.0" },
            purchasesProvider: mockPurchases,
            customerCenterStoreKitUtilities: mockStoreKitUtilities as CustomerCenterStoreKitUtilitiesType
        )

        expect(mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo).to(beNil())

        await viewModel.loadScreen()

        expect(viewModel.subscriptionsSection.first).toNot(beNil())
        expect(viewModel.shouldShowList).to(beFalse())
        expect(mockStoreKitUtilities.renewalPriceFromRenewalInfoCallCount).to(equal(1))
    }

    func testPurchaseInformationUsesInfoFromRenewalInfoWhenAvailable() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let mockStoreKitUtilities = MockCustomerCenterStoreKitUtilities()
        mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo = (5.0, "USD")

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return "3.0.0" },
            purchasesProvider: mockPurchases,
            customerCenterStoreKitUtilities: mockStoreKitUtilities as CustomerCenterStoreKitUtilitiesType
        )

        expect(mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo).to(equal((5, "USD")))

        await viewModel.loadScreen()

        expect(viewModel.shouldShowList).to(beFalse())
        expect(viewModel.subscriptionsSection.first?.pricePaid).to(equal(.nonFree(formatted(price: 4.99))))
        expect(viewModel.subscriptionsSection.first?.renewalPrice).to(equal(.nonFree(formatted(price: 5.0))))
        expect(mockStoreKitUtilities.renewalPriceFromRenewalInfoCallCount).to(equal(1))
    }

    func testOnDismissRestorePurchasesAlertReloadsScreen() async {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let mockPurchases = MockCustomerCenterPurchases(customerInfo: customerInfo)
        let mockStoreKitUtilities = MockCustomerCenterStoreKitUtilities()
        mockStoreKitUtilities.returnRenewalPriceFromRenewalInfo = (5, "USD")

        let viewModel = CustomerCenterViewModel(
            actionWrapper: CustomerCenterActionWrapper(),
            currentVersionFetcher: { return "3.0.0" },
            purchasesProvider: mockPurchases,
            customerCenterStoreKitUtilities: mockStoreKitUtilities as CustomerCenterStoreKitUtilitiesType
        )

        // Initial state
        expect(viewModel.state) == .notLoaded

        await viewModel.loadScreen()

        expect(viewModel.state) == .success

        mockPurchases.customerInfo = CustomerInfoFixtures.customerInfoWithLifetimeAppSubscrition

        // Dismiss alert and verify screen reloads
        viewModel.onDismissRestorePurchasesAlert()

        // Wait for the task to complete
        await viewModel.currentTask?.value
        expect(viewModel.state) == .success

        // Verify screen was reloaded
        expect(viewModel.configuration).toNot(beNil())
        expect(mockPurchases.loadCustomerCenterCallCount) == 2
    }

    func testMultiplePurchases() {
        // empty
        var viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [],
            activeNonSubscriptionPurchases: [],
            configuration: CustomerCenterConfigData.default
        )

        expect(viewModel.shouldShowList).to(beFalse())

        // one active subscription
        viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [.monthlyRenewing],
            activeNonSubscriptionPurchases: [],
            configuration: CustomerCenterConfigData.default
        )

        expect(viewModel.shouldShowList).to(beFalse())

        // two active subscription
        viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [
                .mock(productIdentifier: "1"),
                    .mock(productIdentifier: "2")
            ],
            activeNonSubscriptionPurchases: [],
            configuration: CustomerCenterConfigData.default
        )

        expect(viewModel.shouldShowList).to(beTrue())

        // one active subscription and one purchase
        viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [
                .mock(productIdentifier: "1")
            ],
            activeNonSubscriptionPurchases: [
                .consumable
            ],
            configuration: CustomerCenterConfigData.default
        )

        expect(viewModel.shouldShowList).to(beTrue())

        // one expired subscription
        viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [.expired],
            activeNonSubscriptionPurchases: [],
            configuration: CustomerCenterConfigData.default
        )

        expect(viewModel.shouldShowList).to(beFalse())

        // one expired subscription and one purchase
        viewModel = CustomerCenterViewModel(
            activeSubscriptionPurchases: [.expired],
            activeNonSubscriptionPurchases: [.consumable],
            configuration: CustomerCenterConfigData.default
        )
        expect(viewModel.shouldShowList).to(beTrue())
    }

    private func formatted(price: Decimal, currencyCode: String = "USD") -> String {
        PurchaseInformation.defaultNumberFormatter.currencyCode = currencyCode
        return PurchaseInformation.defaultNumberFormatter.string(from: price as NSNumber)!
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

    static func customerInfoWithGoogleSubscription(
        requestDate: Date,
        entitlementExpiryDate: Date,
        subscriptionExpiryDate: Date
    ) -> CustomerInfo {
        let formatter = ISO8601DateFormatter()

        return .decode(
        """
        {
          "request_date": "\(formatter.string(from: requestDate))",
          "request_date_ms": 1751269357064,
          "subscriber": {
            "entitlements": {
              "MS Math Premium": {
                "expires_date": "\(formatter.string(from: entitlementExpiryDate))",
                "grace_period_expires_date": null,
                "product_identifier": "test_msmath_premium_v1",
                "product_plan_identifier": "msmath-1m-autorenew",
                "purchase_date": "2025-06-30T07:39:30Z"
              }
            },
            "first_seen": "2025-06-26T13:51:09Z",
            "last_seen": "2025-06-30T07:30:49Z",
            "management_url": "https://play.google.com/store/account/subscriptions",
            "non_subscriptions": {},
            "original_app_user_id": "9004c18e-75ff-42f8-9574-961ca0397fbd",
            "original_application_version": null,
            "original_purchase_date": null,
            "other_purchases": {},
            "subscriptions": {
              "test_msmath_premium_v1": {
                "auto_resume_date": null,
                "billing_issues_detected_at": null,
                "display_name": null,
                "expires_date": "\(formatter.string(from: subscriptionExpiryDate))",
                "grace_period_expires_date": null,
                "is_sandbox": true,
                "management_url": "https://play.google.com/store/account/subscriptions",
                "original_purchase_date": "2025-06-30T07:29:31Z",
                "period_type": "normal",
                "price": { "amount": 3.59, "currency": "EUR" },
                "product_plan_identifier": "msmath-1m-autorenew",
                "purchase_date": "2025-06-30T07:39:30Z",
                "refunded_at": null,
                "store": "play_store",
                "store_transaction_id": "GPA.3302-7309-1582-35065..1",
                "unsubscribe_detected_at": null
              }
            }
          }
        }
        """)
    }

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
}

#endif
