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
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class ManageSubscriptionsViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel =
        ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.default,
                                     actionWrapper: CustomerCenterActionWrapper())

        expect(viewModel.state) == CustomerCenterViewState.success
        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.refundRequestStatus).to(beNil())
        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.showRestoreAlert) == false
    }

    func testLifetimeSubscriptionDoesNotShowCancel() {
        let purchase = PurchaseInformation.mockLifetime()

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beFalse())
    }

    func testShowsRefundIfRefundWindowIsForever() {
        let purchase = PurchaseInformation.mockNonLifetime()

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 4
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beTrue())
    }

    func testDoesNotShowRefundIfPurchaseOutsideRefundWindow() {
        let latestPurchaseDate = Date()
        let oneDay = ISODuration(
            years: 0,
            months: 0,
            weeks: 0,
            days: 1,
            hours: 0,
            minutes: 0,
            seconds: 0
        )

        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.managementScreen(refundWindowDuration: .duration(oneDay)),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beFalse())
    }

    func testDoesNotShowRefundIfPurchaseIsFree() {
        let latestPurchaseDate = Date()
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            price: .free,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beFalse())
    }

    func testDoesNotShowRefundIfPurchaseIsWithinTrial() {
        let latestPurchaseDate = Date()
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            price: .paid(""), // just to prove price is ignored if is in trial
            isTrial: true,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beFalse())
    }

    func testShowsRefundIfPurchaseOutsideRefundWindow() {
        let latestPurchaseDate = Date()
        let oneDay = ISODuration(
            years: 0,
            months: 0,
            weeks: 0,
            days: 3,
            hours: 0,
            minutes: 0,
            seconds: 0
        )

        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = ManageSubscriptionsViewModel(
            screen: ManageSubscriptionsViewModelTests.managementScreen(refundWindowDuration: .duration(oneDay)),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase)

        expect(viewModel.relevantPathsForPurchase.count) == 4
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beTrue())
    }

    func testStateChangeToError() {
        let viewModel =
        ManageSubscriptionsViewModel(screen: ManageSubscriptionsViewModelTests.default,
                                     actionWrapper: CustomerCenterActionWrapper())

        viewModel.state = CustomerCenterViewState.error(error)

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
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

        // Test both possible subscription array orders
        let subscriptionOrders = [
            [(id: productIdOne, exp: expirationDateFirst),
             (id: productIdTwo, exp: expirationDateSecond)],
            [(id: productIdTwo, exp: expirationDateSecond),
             (id: productIdOne, exp: expirationDateFirst)]
        ]

        for subscriptions in subscriptionOrders {
            let product = PurchaseInformationFixtures.product(
                id: productIdOne,
                title: "yearly",
                duration: .year,
                price: Decimal(29.99),
                offerIdentifier: offerIdentifier
            )
            let products = [
                product,
                PurchaseInformationFixtures.product(
                    id: productIdTwo,
                    title: "monthly",
                    duration: .month,
                    price: Decimal(2.99)
                )
            ]

            let customerInfo = CustomerInfoFixtures.customerInfo(
                subscriptions: subscriptions.map { subscription in
                    CustomerInfoFixtures.Subscription(
                        id: subscription.id,
                        store: "app_store",
                        purchaseDate: purchaseDate,
                        expirationDate: subscription.exp
                    )
                },
                entitlements: [
                    CustomerInfoFixtures.Entitlement(
                        entitlementId: "premium",
                        productId: productIdOne,
                        purchaseDate: purchaseDate,
                        expirationDate: expirationDateFirst
                    )
                ]
            )

            let promoOfferDetails = CustomerCenterConfigData.HelpPath.PromotionalOffer(
                iosOfferId: offerIdentifier,
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
            let signedData = PromotionalOffer.SignedData(
                identifier: "id",
                keyIdentifier: "key_i",
                nonce: UUID(),
                signature: "a signature",
                timestamp: 1234
            )
            let discount = MockStoreProductDiscount(
                offerIdentifier: offerIdentifier,
                currencyCode: "usd",
                price: 1,
                localizedPriceString: "$1.00",
                paymentMode: .payAsYouGo,
                subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
                numberOfPeriods: 1,
                type: .introductory
            )

            loadPromotionalOfferUseCase.mockedPromotionalOffer = PromotionalOffer(
                discount: discount,
                signedData: signedData
            )

            let viewModel = ManageSubscriptionsViewModel(
                screen: PurchaseInformationFixtures.screenWithIneligiblePromo,
                actionWrapper: CustomerCenterActionWrapper(),
                purchasesProvider: MockManageSubscriptionsPurchases(
                    customerInfo: customerInfo,
                    products: products
                ),
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)

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
                                                          price: Decimal(29.99),
                                                          offerIdentifier: offerIdentifierInProduct)
        let products = [
            product,
            PurchaseInformationFixtures.product(id: productIdTwo, title: "monthly", duration: .month, price: 2.99)
        ]

        // Test both possible subscription array orders
        let subscriptionOrders = [
            [(id: productIdOne, exp: expirationDateFirst),
             (id: productIdTwo, exp: expirationDateSecond)],
            [(id: productIdTwo, exp: expirationDateSecond),
             (id: productIdOne, exp: expirationDateFirst)]
        ]

        let customerInfo = CustomerInfoFixtures.customerInfo(
            subscriptions: subscriptionOrders[0].map { subscription in
                CustomerInfoFixtures.Subscription(
                    id: subscription.id,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: subscription.exp
                )
            },
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
                                                     actionWrapper: CustomerCenterActionWrapper(),
                                                     purchasesProvider: MockManageSubscriptionsPurchases(
                                                        customerInfo: customerInfo,
                                                        products: products
                                                     ),
                                                     loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)

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

    static let `default`: CustomerCenterConfigData.Screen =
    CustomerCenterConfigTestData.customerCenterData.screens[.management]!

    static func managementScreen(
        refundWindowDuration: CustomerCenterConfigData.HelpPath.RefundWindowDuration
    ) -> CustomerCenterConfigData.Screen {
        CustomerCenterConfigTestData.customerCenterData(
            lastPublishedAppVersion: "1.0.0",
            refundWindowDuration: refundWindowDuration).screens[.management]!
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

private extension PurchaseInformation {
    static func mockLifetime(
        customerInfoRequestedDate: Date = Date()
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            durationTitle: "",
            explanation: .lifetime,
            price: .paid(""),
            expirationOrRenewal: PurchaseInformation.ExpirationOrRenewal(label: .expires, date: .date("")),
            productIdentifier: "",
            store: .appStore,
            isTrial: false,
            isLifetime: true,
            latestPurchaseDate: nil,
            customerInfoRequestedDate: customerInfoRequestedDate
        )
    }

    static func mockNonLifetime(
        price: PurchaseInformation.PriceDetails = .paid("5"),
        isTrial: Bool = false,
        latestPurchaseDate: Date = Date(),
        customerInfoRequestedDate: Date = Date()) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            durationTitle: "",
            explanation: .earliestExpiration,
            price: price,
            expirationOrRenewal: PurchaseInformation.ExpirationOrRenewal(
                label: .expires,
                date: .date("")
            ),
            productIdentifier: "",
            store: .appStore,
            isTrial: isTrial,
            isLifetime: false,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: customerInfoRequestedDate
        )
    }
}

#endif
