//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// ManageSubscriptionsViewModelTests.swift
//
//
//  Created by Cesar de la Vega on 11/6/24.
//

// swiftlint:disable file_length type_body_length function_body_length

import Nimble
@testable import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class ManageSubscriptionsViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil)

        expect(viewModel.state) == CustomerCenterViewState.notLoaded
        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.refundRequestStatus).to(beNil())
        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.showRestoreAlert) == false
        expect(viewModel.isLoaded) == false
    }

    func testStateChangeToError() {
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil)

        viewModel.state = CustomerCenterViewState.error(error)

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testIsLoaded() {
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil)

        expect(viewModel.isLoaded) == false

        viewModel.state = .success

        expect(viewModel.isLoaded) == true
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

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.screen).toNot(beNil())
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

    func testShouldShowEarliestExpiration_whenUserHasTwoActiveSubscriptionsOneEntitlement() async throws {
        for subscriptionsOrder in [
            [(id: "com.revenuecat.product1", exp: "2062-04-12T00:03:35Z"),
             (id: "com.revenuecat.product2", exp: "2062-05-12T00:03:35Z")],
            [(id: "com.revenuecat.product2", exp: "2062-05-12T00:03:35Z"),
             (id: "com.revenuecat.product1", exp: "2062-04-12T00:03:35Z")]
        ] {
            // Arrange
            let productIdOne = subscriptionsOrder[0].id
            let productIdTwo = subscriptionsOrder[1].id
            let purchaseDate = "2022-04-12T00:03:28Z"
            let expirationDateFirst = subscriptionsOrder[0].exp
            let expirationDateSecond = subscriptionsOrder[1].exp
            let products = [
                PurchaseInformationFixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
                PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
            ]
            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: [
                    CustomerInfoFixtures.Subscription(
                        id: productIdOne,
                        store: "app_store",
                        purchaseDate: purchaseDate,
                        expirationDate: expirationDateFirst
                    ),
                    CustomerInfoFixtures.Subscription(
                        id: productIdTwo,
                        store: "app_store",
                        purchaseDate: purchaseDate,
                        expirationDate: expirationDateSecond
                    )
                ],
                entitlements: [
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: "premium",
                        productId: "com.revenuecat.product1",
                        purchaseDate: purchaseDate,
                        expirationDate: "2062-04-12T00:03:35Z"
                    )
                ]
            )

            let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                       customerCenterActionHandler: nil,
                                                       purchasesProvider: MockManageSubscriptionsPurchases(
                                                          customerInfo: customerInfo,
                                                          products: products
                                                       ),
                                                       loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

            // Act
            await viewModel.loadScreen()

            // Assert
            expect(viewModel.screen).toNot(beNil())
            expect(viewModel.state) == .success

            let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
            expect(purchaseInformation.title) == "yearly"
            expect(purchaseInformation.durationTitle) == "1 year"
            expect(purchaseInformation.price) == .paid("$29.99")

            let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
            expect(expirationOrRenewal.label) == .nextBillingDate
            expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: "2062-04-12T00:03:35Z"))

            expect(purchaseInformation.productIdentifier) == "com.revenuecat.product1"
        }
    }

    func testShouldShowLifetime_whenUserHasLifetimeAndSubscriptionsOneEntitlement() async throws {
        let productIdLifetime = "com.revenuecat.simpleapp.lifetime"
        let productIdMonthly = "com.revenuecat.simpleapp.monthly"
        let productIdYearly = "com.revenuecat.simpleapp.yearly"
        let purchaseDateLifetime = "2024-11-21T16:04:20Z"
        let purchaseDateMonthly = "2024-11-21T16:04:39Z"
        let purchaseDateYearly = "2024-11-21T16:04:45Z"
        let expirationDateMonthly = "2024-11-28T16:04:39Z"
        let expirationDateYearly = "2025-11-21T16:04:45Z"

        let products = [
            PurchaseInformationFixtures.product(id: productIdLifetime,
                                                    title: "lifetime",
                                                    duration: nil,
                                                    price: 29.99),
            PurchaseInformationFixtures.product(id: productIdMonthly,
                                                    title: "monthly",
                                                    duration: .month,
                                                    price: 2.99),
            PurchaseInformationFixtures.product(id: productIdYearly,
                                                    title: "yearly",
                                                    duration: .year,
                                                    price: 29.99)
        ]

        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productIdMonthly,
                    store: "app_store",
                    purchaseDate: purchaseDateMonthly,
                    expirationDate: expirationDateMonthly
                ),
                CustomerInfoFixtures.Subscription(
                    id: productIdYearly,
                    store: "app_store",
                    purchaseDate: purchaseDateYearly,
                    expirationDate: expirationDateYearly
                )
            ].shuffled(),
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

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title) == "lifetime"
        expect(purchaseInformation.durationTitle).to(beNil())
        expect(purchaseInformation.price) == .paid("$29.99")
        expect(purchaseInformation.productIdentifier) == productIdLifetime

        expect(purchaseInformation.expirationOrRenewal?.date) == .never
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

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.screen).toNot(beNil())
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
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let products = [
            PurchaseInformationFixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
            PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "plus",
                    productId: productIdTwo,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled()
        )

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        expect(purchaseInformation.title) == "yearly"
        expect(purchaseInformation.durationTitle) == "1 year"
        expect(purchaseInformation.price) == .paid("$29.99")

        let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: expirationDateFirst))

        expect(purchaseInformation.productIdentifier) == productIdOne
    }

    func testShouldShowAppleSubscription_whenUserHasBothGoogleAndAppleSubscriptions() async throws {
        // Arrange
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let products = [
            PurchaseInformationFixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
            PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productIdOne,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "plus",
                    productId: productIdTwo,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled()
        )

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        // Act
        await viewModel.loadScreen()

        // Assert
        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.state) == .success

        let purchaseInformation = try XCTUnwrap(viewModel.purchaseInformation)
        // We expect to see the monthly one, because the yearly one is a Google subscription.
        expect(purchaseInformation.title) == "monthly"
        expect(purchaseInformation.durationTitle) == "1 month"

        expect(purchaseInformation.price) == .paid("$2.99")

        let expirationOrRenewal = try XCTUnwrap(purchaseInformation.expirationOrRenewal)
        expect(expirationOrRenewal.label) == .nextBillingDate
        expect(expirationOrRenewal.date) == .date(reformat(ISO8601Date: expirationDateSecond))

        expect(purchaseInformation.productIdentifier) == productIdTwo
    }

    func testLoadScreenNoActiveSubscription() async {
        let customerInfo = CustomerInfoFixtures.customerInfoWithExpiredAppleSubscriptions
        let mockPurchases = MockManageSubscriptionsPurchases(customerInfo: customerInfo)
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: mockPurchases,
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .error(CustomerCenterError.couldNotFindSubscriptionInformation)
    }

    func testLoadScreenFailure() async {
        let mockPurchases = MockManageSubscriptionsPurchases(customerInfoError: error)
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: mockPurchases,
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.state) == .error(error)
    }

    func testLoadsPromotionalOffer() async throws {
        let offerIdentifierInJSON = "rc_refund_offer"
        let (viewModel, loadPromotionalOfferUseCase) = try await setupPromotionalOfferTest(
            offerIdentifierInJSON: offerIdentifierInJSON,
            offerIdentifierInProduct: offerIdentifierInJSON
        )

        try await verifyPromotionalOfferLoading(viewModel: viewModel,
                                                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase,
                                                expectedOfferIdentifierInJSON: offerIdentifierInJSON)
    }

    func testLoadsPromotionalOfferWithSuffix() async throws {
        let offerIdentifierInJSON = "rc_refund_offer"
        let offerIdentifierInProduct = "monthly_rc_refund_offer"
        let (viewModel, loadPromotionalOfferUseCase) = try await setupPromotionalOfferTest(
            offerIdentifierInJSON: offerIdentifierInJSON,
            offerIdentifierInProduct: offerIdentifierInProduct
        )

        try await verifyPromotionalOfferLoading(viewModel: viewModel,
                                                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase,
                                                expectedOfferIdentifierInJSON: offerIdentifierInJSON,
                                                expectedOfferIdentifierInProduct: offerIdentifierInProduct)
    }

    func testDoesNotLoadPromotionalOfferIfNotEligible() async throws {
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let offerIdentifier = "offer_id"
        let product = PurchaseInformationFixtures.product(id: productIdOne,
                                                              title: "yearly",
                                                              duration: .year,
                                                              price: 29.99,
                                                              offerIdentifier: offerIdentifier)
        let products = [
            product,
            PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                )
            ]
        )
        let promoOfferDetails = CustomerCenterConfigData.HelpPath.PromotionalOffer(iosOfferId: offerIdentifier,
                                                                                   eligible: false,
                                                                                   title: "Wait",
                                                                                   subtitle: "Here's an offer for you",
                                                                                   productMapping: [
                                                                                    "product_id": "offer_id"
                                                                                   ]
        )
        let loadPromotionalOfferUseCase = MockLoadPromotionalOfferUseCase()
        loadPromotionalOfferUseCase.mockedProduct = product
        loadPromotionalOfferUseCase.mockedPromoOfferDetails = promoOfferDetails
        let signedData = PromotionalOffer.SignedData(identifier: "id",
                                                     keyIdentifier: "key_i",
                                                     nonce: UUID(),
                                                     signature: "a signature",
                                                     timestamp: 1234)
        let discount = MockStoreProductDiscount(offerIdentifier: offerIdentifier,
                                                currencyCode: "usd",
                                                price: 1,
                                                localizedPriceString: "$1.00",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
                                                numberOfPeriods: 1,
                                                type: .introductory)

        loadPromotionalOfferUseCase.mockedPromotionalOffer = PromotionalOffer(discount: discount,
                                                                              signedData: signedData)

        let viewModel = ManageSubscriptionsViewModel(screen: PurchaseInformationFixtures.screenWithIneligiblePromo,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)

        await viewModel.loadScreen()

        let screen = try XCTUnwrap(viewModel.screen)
        expect(viewModel.state) == .success

        let pathWithPromotionalOffer = try XCTUnwrap(screen.paths.first { path in
            if case .promotionalOffer = path.detail {
                return true
            }
            return false
        })

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())

        await viewModel.determineFlow(for: pathWithPromotionalOffer)

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())
    }

    // Helper methods
    private func setupPromotionalOfferTest(offerIdentifierInJSON: String,
                                           offerIdentifierInProduct: String
    ) async throws -> (ManageSubscriptionsViewModel, MockLoadPromotionalOfferUseCase) {
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"

        let product = PurchaseInformationFixtures.product(id: productIdOne,
                                                              title: "yearly",
                                                              duration: .year,
                                                              price: 29.99,
                                                              offerIdentifier: offerIdentifierInProduct)
        let products = [
            product,
            PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: [
                CustomerInfoFixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                CustomerInfoFixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                CustomerInfoFixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                )
            ]
        )
        let promoOfferDetails =
        CustomerCenterConfigData.HelpPath.PromotionalOffer(iosOfferId: offerIdentifierInJSON,
                                                           eligible: true,
                                                           title: "Wait",
                                                           subtitle: "Here's an offer for you",
                                                           productMapping: [
                                                            "product_id": "offer_id"
                                                           ])
        let loadPromotionalOfferUseCase = MockLoadPromotionalOfferUseCase()
        loadPromotionalOfferUseCase.mockedProduct = product
        loadPromotionalOfferUseCase.mockedPromoOfferDetails = promoOfferDetails
        let signedData = PromotionalOffer.SignedData(identifier: "id",
                                                     keyIdentifier: "key_i",
                                                     nonce: UUID(),
                                                     signature: "a signature",
                                                     timestamp: 1234)
        let discount = MockStoreProductDiscount(offerIdentifier: offerIdentifierInProduct,
                                                currencyCode: "usd",
                                                price: 1,
                                                localizedPriceString: "$1.00",
                                                paymentMode: .payAsYouGo,
                                                subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
                                                numberOfPeriods: 1,
                                                type: .introductory)

        loadPromotionalOfferUseCase.mockedPromotionalOffer = PromotionalOffer(discount: discount,
                                                                              signedData: signedData)

        let screen = PurchaseInformationFixtures.screenWithPromo(offerID: offerIdentifierInJSON)
        let viewModel = ManageSubscriptionsViewModel(screen: screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)

        await viewModel.loadScreen()

        return (viewModel, loadPromotionalOfferUseCase)
    }

    private func verifyPromotionalOfferLoading(viewModel: ManageSubscriptionsViewModel,
                                               loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase,
                                               expectedOfferIdentifierInJSON: String,
                                               expectedOfferIdentifierInProduct: String? = nil) async throws {
        let screen = try XCTUnwrap(viewModel.screen)
        expect(viewModel.state) == .success

        let pathWithPromotionalOffer = try XCTUnwrap(screen.paths.first { path in
            if case .promotionalOffer = path.detail {
                return true
            }
            return false
        })

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())

        await viewModel.determineFlow(for: pathWithPromotionalOffer)

        let loadingPath = try XCTUnwrap(viewModel.loadingPath)
        expect(loadingPath.id) == pathWithPromotionalOffer.id

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor?.iosOfferId) == expectedOfferIdentifierInJSON

        if let expectedOfferIdentifierInProduct = expectedOfferIdentifierInProduct {
            expect(
                loadPromotionalOfferUseCase.mockedPromotionalOffer?.discount.offerIdentifier
            ) == expectedOfferIdentifierInProduct
        }
    }

    private func reformat(ISO8601Date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: ISO8601DateFormatter().date(from: ISO8601Date)!)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class MockManageSubscriptionsPurchases: ManageSubscriptionsPurchaseType {

    let customerInfo: CustomerInfo
    let customerInfoError: Error?
    // StoreProducts keyed by productIdentifier.
    let products: [String: RevenueCat.StoreProduct]
    let showManageSubscriptionsError: Error?
    let beginRefundShouldFail: Bool

    init(
        customerInfo: CustomerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
        customerInfoError: Error? = nil,
        products: [RevenueCat.StoreProduct] =
        [PurchaseInformationFixtures.product(id: "com.revenuecat.product",
                                                 title: "title",
                                                 duration: .month,
                                                 price: 2.99)],
        showManageSubscriptionsError: Error? = nil,
        beginRefundShouldFail: Bool = false
    ) {
        self.customerInfo = customerInfo
        self.customerInfoError = customerInfoError
        self.products = Dictionary(uniqueKeysWithValues: products.map({ product in
            (product.productIdentifier, product)
        }))
        self.showManageSubscriptionsError = showManageSubscriptionsError
        self.beginRefundShouldFail = beginRefundShouldFail
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        if let customerInfoError {
            throw customerInfoError
        }
        return customerInfo
    }

    func products(_ productIdentifiers: [String]) async -> [RevenueCat.StoreProduct] {
        return productIdentifiers.compactMap { productIdentifier in
            products[productIdentifier]
        }
    }

    func showManageSubscriptions() async throws {
        if let showManageSubscriptionsError {
            throw showManageSubscriptionsError
        }
    }

    func beginRefundRequest(forProduct productID: String) async throws -> RevenueCat.RefundRequestStatus {
        if beginRefundShouldFail {
            return .error
        }
        return .success
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ManageSubscriptionsViewModelTests {

    static let screen: CustomerCenterConfigData.Screen =
    CustomerCenterConfigTestData.customerCenterData.screens[.management]!

}

private struct MockStoreProductDiscount: StoreProductDiscountType {

    let offerIdentifier: String?
    let currencyCode: String?
    let price: Decimal
    let localizedPriceString: String
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod
    let numberOfPeriods: Int
    let type: StoreProductDiscount.DiscountType

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class MockLoadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType {

    var offerToLoadPromoFor: RevenueCat.CustomerCenterConfigData.HelpPath.PromotionalOffer?

    var mockedProduct: StoreProduct?
    var mockedPromotionalOffer: PromotionalOffer?
    var mockedPromoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer?

    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) async -> Result<PromotionalOfferData, Error> {
        self.offerToLoadPromoFor = promoOfferDetails
        if let mockedProduct = mockedProduct,
           let mockedPromotionalOffer = mockedPromotionalOffer,
           let mockedPromoOfferDetails = mockedPromoOfferDetails {
            return .success(PromotionalOfferData(promotionalOffer: mockedPromotionalOffer,
                                                 product: mockedProduct,
                                                 promoOfferDetails: mockedPromoOfferDetails))
        } else {
            return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
        }

    }

}

#endif
