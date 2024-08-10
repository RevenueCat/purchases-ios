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

#if CUSTOMER_CENTER_ENABLED

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
        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.refundRequestStatusMessage).to(beNil())
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
        let products = [Fixtures.product(id: productId, title: "title", duration: .month, price: 2.99)]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Fixtures.Entitlement(
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

        let subscriptionInformation = try XCTUnwrap(viewModel.subscriptionInformation)
        expect(subscriptionInformation.title) == "title"
        expect(subscriptionInformation.durationTitle) == "month"
        expect(subscriptionInformation.price) == "$2.99"
        expect(subscriptionInformation.expirationDateString) == reformat(ISO8601Date: expirationDate)
        expect(subscriptionInformation.productIdentifier) == productId
    }

    func testShouldShowEarliestExpiration_whenUserHasTwoActiveSubscriptionsOneEntitlement() async throws {
        // Arrange
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let products = [
            Fixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
            Fixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                Fixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
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

        let subscriptionInformation = try XCTUnwrap(viewModel.subscriptionInformation)
        expect(subscriptionInformation.title) == "yearly"
        expect(subscriptionInformation.durationTitle) == "year"
        expect(subscriptionInformation.price) == "$29.99"
        expect(subscriptionInformation.expirationDateString) == reformat(ISO8601Date: expirationDateFirst)
        expect(subscriptionInformation.productIdentifier) == productIdOne
    }

    func testShouldShowEarliestExpiration_whenUserHasTwoActiveSubscriptionsTwoEntitlements() async throws {
        // Arrange
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let products = [
            Fixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
            Fixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                Fixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Entitlement(
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

        let subscriptionInformation = try XCTUnwrap(viewModel.subscriptionInformation)
        expect(subscriptionInformation.title) == "yearly"
        expect(subscriptionInformation.durationTitle) == "year"
        expect(subscriptionInformation.price) == "$29.99"
        expect(subscriptionInformation.expirationDateString) == reformat(ISO8601Date: expirationDateFirst)
        expect(subscriptionInformation.productIdentifier) == productIdOne
    }

    func testShouldShowAppleSubscription_whenUserHasBothGoogleAndAppleSubscriptions() async throws {
        // Arrange
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let products = [
            Fixtures.product(id: productIdOne, title: "yearly", duration: .year, price: 29.99),
            Fixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productIdOne,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                Fixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Entitlement(
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

        let subscriptionInformation = try XCTUnwrap(viewModel.subscriptionInformation)
        // We expect to see the monthly one, because the yearly one is a Google subscription.
        expect(subscriptionInformation.title) == "monthly"
        expect(subscriptionInformation.durationTitle) == "month"
        expect(subscriptionInformation.price) == "$2.99"
        expect(subscriptionInformation.expirationDateString) == reformat(ISO8601Date: expirationDateSecond)
        expect(subscriptionInformation.productIdentifier) == productIdTwo
    }

    func testLoadScreenNoActiveSubscription() async {
        let mockPurchases = MockManageSubscriptionsPurchases(customerInfo: Fixtures.customerInfoWithoutSubscriptions)
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: mockPurchases,
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.state) == .error(CustomerCenterError.couldNotFindSubscriptionInformation)
    }

    func testLoadScreenFailure() async {
        let mockPurchases = MockManageSubscriptionsPurchases(customerInfoError: error)
        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
                                                     customerCenterActionHandler: nil,
                                                     purchasesProvider: mockPurchases,
                                                     loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase())

        await viewModel.loadScreen()

        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.state) == .error(error)
    }

    func testLoadsPromotionalOffer() async throws {
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let offerIdentifier = "offer_id"
        let product = Fixtures.product(id: productIdOne,
                                       title: "yearly",
                                       duration: .year,
                                       price: 29.99,
                                       offerIdentifier: offerIdentifier)
        let products = [
            product,
            Fixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                Fixtures.Entitlement(
                    entitlementId: "premium",
                    productId: productIdOne,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                )
            ]
        )
        let promoOfferDetails = CustomerCenterConfigData.HelpPath.PromotionalOffer(iosOfferId: offerIdentifier,
                                                                                   eligible: true,
                                                                                   title: "Wait",
                                                                                   subtitle: "Here's an offer for you")
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

        let viewModel = ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.screen,
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

        let loadingPath = try XCTUnwrap(viewModel.loadingPath)
        expect(loadingPath.id) == pathWithPromotionalOffer.id

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor?.iosOfferId) == offerIdentifier
    }

    func testDoesNotLoadPromotionalOfferIfNotEligible() async throws {
        let productIdOne = "com.revenuecat.product1"
        let productIdTwo = "com.revenuecat.product2"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDateFirst = "2062-04-12T00:03:35Z"
        let expirationDateSecond = "2062-05-12T00:03:35Z"
        let offerIdentifier = "offer_id"
        let product = Fixtures.product(id: productIdOne,
                                       title: "yearly",
                                       duration: .year,
                                       price: 29.99,
                                       offerIdentifier: offerIdentifier)
        let products = [
            product,
            Fixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]
        let customerInfo = Fixtures.customerInfo(
            subscriptions: [
                Fixtures.Subscription(
                    id: productIdOne,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateFirst
                ),
                Fixtures.Subscription(
                    id: productIdTwo,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDateSecond
                )
            ].shuffled(),
            entitlements: [
                Fixtures.Entitlement(
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
                                                                                   subtitle: "Here's an offer for you")
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

        let viewModel = ManageSubscriptionsViewModel(screen: Fixtures.screenWithIneligiblePromo,
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
        customerInfo: CustomerInfo = Fixtures.customerInfoWithAppleSubscriptions,
        customerInfoError: Error? = nil,
        products: [RevenueCat.StoreProduct] =
            [Fixtures.product(id: "com.revenuecat.product", title: "title", duration: .month, price: 2.99)],
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
private class Fixtures {

    private init() {}

    class Subscription {

        let id: String
        let json: String

        init(id: String, store: String, purchaseDate: String, expirationDate: String) {
            self.id = id
            self.json = """
            {
                "billing_issues_detected_at": null,
                "expires_date": "\(expirationDate)",
                "grace_period_expires_date": null,
                "is_sandbox": true,
                "original_purchase_date": "\(purchaseDate)",
                "period_type": "intro",
                "purchase_date": "\(purchaseDate)",
                "store": "\(store)",
                "unsubscribe_detected_at": null
            }
            """
        }

    }

    class Entitlement {

        let id: String
        let json: String

        init(entitlementId: String, productId: String, purchaseDate: String, expirationDate: String) {
            self.id = entitlementId
            self.json = """
            {
                "expires_date": "\(expirationDate)",
                "product_identifier": "\(productId)",
                "purchase_date": "\(purchaseDate)"
            }
            """
        }

    }

    static func product(
        id: String,
        title: String,
        duration: SKProduct.PeriodUnit,
        price: Decimal,
        priceLocale: String = "en_US",
        offerIdentifier: String? = nil
    ) -> StoreProduct {
        // Using SK1 products because they can be mocked, but CustomerCenterViewModel
        // works with generic `StoreProduct`s regardless of what they contain
        let sk1Product = MockSK1Product(mockProductIdentifier: id, mockLocalizedTitle: title)
        sk1Product.mockPrice = price
        sk1Product.mockPriceLocale = Locale(identifier: priceLocale)
        sk1Product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: duration)
        if let offerIdentifier = offerIdentifier {
            sk1Product.mockDiscount = SKProductDiscount(identifier: offerIdentifier)
        }
        return StoreProduct(sk1Product: sk1Product)
    }

    static func customerInfo(subscriptions: [Subscription], entitlements: [Entitlement]) -> CustomerInfo {
        let subscriptionsJson = subscriptions.map { subscription in
            """
            "\(subscription.id)": \(subscription.json)
            """
        }.joined(separator: ",\n")

        let entitlementsJson = entitlements.map { entitlement in
            """
            "\(entitlement.id)": \(entitlement.json)
            """
        }.joined(separator: ",\n")

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
                    \(subscriptionsJson)
                },
                "entitlements": {
                    \(entitlementsJson)
                }
            }
        }
        """
        )
    }

    static let customerInfoWithAppleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithGoogleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithoutSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "1999-04-12T00:03:28Z"
        let expirationDate = "2000-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let screenWithIneligiblePromo: CustomerCenterConfigData.Screen = .init(
        type: .management,
        title: "Manage Subscription",
        subtitle: "Manage your subscription details here",
        paths: [
            .init(
                id: "1",
                title: "Didn't receive purchase",
                type: .missingPurchase,
                detail: .promotionalOffer(CustomerCenterConfigData.HelpPath.PromotionalOffer(
                    iosOfferId: "offer_id",
                    eligible: false,
                    title: "title",
                    subtitle: "subtitle"
                ))
            )
        ]
    )

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ManageSubscriptionsViewModelTests {

    static let screen: CustomerCenterConfigData.Screen =
    CustomerCenterConfigTestData.customerCenterData.screens[.management]!

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class MockSK1Product: SK1Product {

    var mockProductIdentifier: String
    var mockLocalizedTitle: String

    init(mockProductIdentifier: String, mockLocalizedTitle: String) {
        self.mockProductIdentifier = mockProductIdentifier
        self.mockLocalizedTitle = mockLocalizedTitle

        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }

    var mockSubscriptionGroupIdentifier: String?
    override var subscriptionGroupIdentifier: String? {
        return self.mockSubscriptionGroupIdentifier
    }

    var mockPriceLocale: Locale?
    override var priceLocale: Locale {
        return mockPriceLocale ?? Locale(identifier: "en_US")
    }

    var mockPrice: Decimal?
    override var price: NSDecimalNumber {
        return (mockPrice ?? 2.99) as NSDecimalNumber
    }

    override var localizedTitle: String {
        return self.mockLocalizedTitle
    }

    override var introductoryPrice: SKProductDiscount? {
        return mockDiscount
    }

    private var _mockDiscount: Any?

    var mockDiscount: SKProductDiscount? {
        // swiftlint:disable:next force_cast
        get { return self._mockDiscount as! SKProductDiscount? }
        set { self._mockDiscount = newValue }
    }

    override var discounts: [SKProductDiscount] {
        return self.mockDiscount.map { [$0] } ?? []
    }

    private lazy var _mockSubscriptionPeriod: Any? = {
        return SKProductSubscriptionPeriod(numberOfUnits: 1, unit: SKProduct.PeriodUnit.month)
    }()

    var mockSubscriptionPeriod: SKProductSubscriptionPeriod? {
        // swiftlint:disable:next force_cast
        get { self._mockSubscriptionPeriod as! SKProductSubscriptionPeriod? }
        set { self._mockSubscriptionPeriod = newValue }
    }

    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return mockSubscriptionPeriod
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension SKProductSubscriptionPeriod {

    convenience init(numberOfUnits: Int,
                     unit: SK1Product.PeriodUnit) {
        self.init()
        self.setValue(numberOfUnits, forKey: "numberOfUnits")
        self.setValue(unit.rawValue, forKey: "unit")
    }

}

fileprivate extension SKProductDiscount {

    convenience init(identifier: String) {
        self.init()
        self.setValue(identifier, forKey: "identifier")
        self.setValue(subscriptionPeriod, forKey: "subscriptionPeriod")
    }

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
class MockLoadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType {

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

#endif
