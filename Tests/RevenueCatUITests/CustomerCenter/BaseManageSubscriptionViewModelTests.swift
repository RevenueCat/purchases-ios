//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// BaseManageSubscriptionViewModel.swift
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
final class BaseManageSubscriptionViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel =
        BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: nil,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.purchaseInformation).to(beNil())
        expect(viewModel.refundRequestStatus).to(beNil())
        expect(viewModel.screen).toNot(beNil())
        expect(viewModel.showRestoreAlert) == false
    }

    func testNoPurchaseOnlyMissingPurchasePath() {
        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: nil,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .missingPurchase })).to(beTrue())
    }

    func testNonAppStoreFiltersAppStoreOnlyPaths() {
        let purchase = PurchaseInformation.mockNonLifetime(store: .playStore)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beTrue())
    }

    func testNonAppStoreFiltersAppStoreOnlyPathsAndCancelIfNoURL() {
        let purchase = PurchaseInformation.mockNonLifetime(store: .playStore, managementURL: nil)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 0
    }

    func testLifetimeCantBeRefunded() {
        let purchase = PurchaseInformation.lifetime

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.first(where: { $0.type == .refundRequest })).toNot(beNil())
    }

    func testLifetimeSubscriptionDoesNotShowCancel() {
        let purchase = PurchaseInformation.mockLifetime()

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).toNot(beNil())
    }

    func testCancelledDoesNotShowCancelAndRefund() {
        let purchase = PurchaseInformation.mockNonLifetime(
            isCancelled: true
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
    }

    func testShowsRefundIfRefundWindowIsForever() {
        let purchase = PurchaseInformation.mockNonLifetime()

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).toNot(beNil())
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

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.managementScreen(refundWindowDuration: .duration(oneDay)),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 2
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).toNot(beNil())
    }

    func testDoesNotShowRefundIfPurchaseIsFree() {
        let latestPurchaseDate = Date()
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            pricePaid: .free,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 2
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).toNot(beNil())
    }

    func testDoesNotShowRefundIfPurchaseIsWithinTrial() {
        let latestPurchaseDate = Date()
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mockNonLifetime(
            pricePaid: .nonFree(""), // just to prove price is ignored if is in trial
            isTrial: true,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays))

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.managementScreen(refundWindowDuration: .forever),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 2
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).toNot(beNil())
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

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.managementScreen(refundWindowDuration: .duration(oneDay)),
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases())

        expect(viewModel.relevantPathsForPurchase.count) == 3
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).toNot(beNil())
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).toNot(beNil())
    }

    func testLoadsPromotionalOffer() async throws {
        let offerIdentifierInJSON = "rc_refund_offer"
        let (viewModel, loadPromotionalOfferUseCase) = try await setupPromotionalOfferTest(
            offerIdentifierInJSON: offerIdentifierInJSON,
            offerIdentifierInProduct: offerIdentifierInJSON
        )

        try await verifyPromotionalOfferLoading(
            viewModel: viewModel,
            loadPromotionalOfferUseCase: loadPromotionalOfferUseCase,
            expectedOfferIdentifierInJSON: offerIdentifierInJSON
        )
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

            let viewModel = BaseManageSubscriptionViewModel(
                screen: PurchaseInformationFixtures.screenWithIneligiblePromo,
                actionWrapper: CustomerCenterActionWrapper(),
                purchaseInformation: nil,
                purchasesProvider: MockCustomerCenterPurchases(
                    customerInfo: customerInfo,
                    products: products
                ),
                loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)

            let screen = try XCTUnwrap(viewModel.screen)

            let pathWithPromotionalOffer = try XCTUnwrap(screen.paths.first { path in
                if case .promotionalOffer = path.detail {
                    return true
                }
                return false
            })

            expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())

            await viewModel.handleHelpPath(pathWithPromotionalOffer)

            expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())
        }
    }

    // Helper methods
    private func setupPromotionalOfferTest(offerIdentifierInJSON: String,
                                           offerIdentifierInProduct: String
    ) async throws -> (BaseManageSubscriptionViewModel, MockLoadPromotionalOfferUseCase) {
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
        let viewModel = BaseManageSubscriptionViewModel(screen: screen,
                                                        actionWrapper: CustomerCenterActionWrapper(),
                                                        purchaseInformation: .yearlyExpiring(store: .appStore),
                                                        purchasesProvider: MockCustomerCenterPurchases(
                                                            customerInfo: customerInfo,
                                                            products: products
                                                        ),
                                                        loadPromotionalOfferUseCase: loadPromotionalOfferUseCase)
        viewModel.feedbackSurveyData = FeedbackSurveyData(
            productIdentifier: viewModel.purchaseInformation!.productIdentifier,
            configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey(
                title: "title",
                options: []
                ),
                path: CustomerCenterConfigData.HelpPath(
                    id: "id",
                    title: "title",
                    type: .cancel,
                    detail: nil
                ),
                onOptionSelected: {}
            )
            return (viewModel, loadPromotionalOfferUseCase)
    }

    private func verifyPromotionalOfferLoading(viewModel: BaseManageSubscriptionViewModel,
                                               loadPromotionalOfferUseCase: MockLoadPromotionalOfferUseCase,
                                               expectedOfferIdentifierInJSON: String,
                                               expectedOfferIdentifierInProduct: String? = nil) async throws {
        let screen = try XCTUnwrap(viewModel.screen)

        let pathWithPromotionalOffer = try XCTUnwrap(screen.paths.first { path in
            if case .promotionalOffer = path.detail {
                return true
            }
            return false
        })

        expect(loadPromotionalOfferUseCase.offerToLoadPromoFor).to(beNil())

        await viewModel.handleHelpPath(pathWithPromotionalOffer)

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
private extension BaseManageSubscriptionViewModelTests {

    static let `default`: CustomerCenterConfigData.Screen =
    CustomerCenterConfigData.default.screens[.management]!

    static func managementScreen(
        refundWindowDuration: CustomerCenterConfigData.HelpPath.RefundWindowDuration
    ) -> CustomerCenterConfigData.Screen {
        CustomerCenterConfigData.mock(
            lastPublishedAppVersion: "1.0.0",
            refundWindowDuration: refundWindowDuration).screens[.management]!
    }

}

private extension PurchaseInformation {
    static func mockLifetime(
        customerInfoRequestedDate: Date = Date(),
        store: Store = .appStore
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            pricePaid: .nonFree(""),
            renewalPrice: nil,
            productIdentifier: "",
            store: store,
            isLifetime: true,
            isTrial: false,
            isCancelled: false,
            isActive: true,
            latestPurchaseDate: Date(),
            customerInfoRequestedDate: customerInfoRequestedDate,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )
    }

    static func mockNonLifetime(
        store: Store = .appStore,
        pricePaid: PurchaseInformation.PricePaid = .nonFree("5"),
        renewalPrice: PurchaseInformation.RenewalPrice = .nonFree("5"),
        isTrial: Bool = false,
        isCancelled: Bool = false,
        latestPurchaseDate: Date = Date(),
        customerInfoRequestedDate: Date = Date(),
        managementURL: URL? = URL(string: "https://www.revenuecat.com")!
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            pricePaid: pricePaid,
            renewalPrice: renewalPrice,
            productIdentifier: "",
            store: store,
            isLifetime: false,
            isTrial: isTrial,
            isCancelled: isCancelled,
            isActive: true,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: customerInfoRequestedDate,
            managementURL: managementURL
        )
    }
}

#endif
