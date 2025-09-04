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

import Combine
import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
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
    private var cancellables = Set<AnyCancellable>()

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    override func setUp() {
        super.setUp()

        cancellables.removeAll()
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
        expect(viewModel.showAllInAppCurrenciesScreen).to(equal(false))
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
        let purchase = PurchaseInformation.mock(
            store: .playStore,
            isSubscription: true
        )

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
        let purchase = PurchaseInformation.mock(store: .playStore, managementURL: nil)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 0
    }

    func testLifetimeSubscriptionPaths() {
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

    func testCancelledDoesNotShowCancelAndRefund() {
        let purchase = PurchaseInformation.mock(
            isSubscription: true,
            productType: .autoRenewableSubscription,
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
        let purchase = PurchaseInformation.mock(
            isSubscription: true,
            productType: .autoRenewableSubscription
        )

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
        let purchase = PurchaseInformation.mock(
            isSubscription: true,
            productType: .autoRenewableSubscription,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays)
        )

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

    func testDoesNotShowRefundIfPricePaidIsFree() {
        let latestPurchaseDate = Date()
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let purchase = PurchaseInformation.mock(
            pricePaid: .free,
            isSubscription: true,
            productType: .autoRenewableSubscription,
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
        let purchase = PurchaseInformation.mock(
            pricePaid: .nonFree(""), // just to prove price is ignored if is in trial
            isSubscription: true,
            productType: .autoRenewableSubscription,
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
        let purchase = PurchaseInformation.mock(
            isSubscription: true,
            productType: .autoRenewableSubscription,
            latestPurchaseDate: latestPurchaseDate,
            customerInfoRequestedDate: latestPurchaseDate.addingTimeInterval(twoDays)
        )

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

    func testDisplayAllInAppCurrenciesScreen() async throws {
        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: nil,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.showAllInAppCurrenciesScreen).to(equal(false))

        viewModel.displayAllInAppCurrenciesScreen()

        expect(viewModel.showAllInAppCurrenciesScreen).to(equal(true))
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
                                                        purchaseInformation: .mock(store: .appStore, isExpired: false),
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

    func testCustomActionPathHandling() async throws {
        let purchaseInformation = PurchaseInformation.subscription
        let actionWrapper = CustomerCenterActionWrapper()
        var capturedCustomActionData: CustomActionData?

        // Set up expectation to capture custom action
        let expectation = XCTestExpectation(description: "Custom action triggered")

        // Monitor the customActionSelected publisher
        actionWrapper
            .onCustomerCenterCustomActionSelected({  actionIdentifier, purchaseIdentifier in
                capturedCustomActionData = CustomActionData(
                    actionIdentifier: actionIdentifier,
                    purchaseIdentifier: purchaseIdentifier
                )
                expectation.fulfill()
            })
            .store(in: &cancellables)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: Self.managementScreen(refundWindowDuration: .forever),
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Create a custom action path
        let customActionPath = CustomerCenterConfigData.HelpPath(
            id: "custom_delete_user",
            title: "Delete Account",
            type: .customAction,
            detail: nil,
            customActionIdentifier: "delete_user"
        )

        // Call handleHelpPath with the custom action
        await viewModel.handleHelpPath(customActionPath, withActiveProductId: purchaseInformation.productIdentifier)

        // Wait for the action to be triggered
        await fulfillment(of: [expectation], timeout: 1.0)

        // Verify that the correct custom action was triggered
        let customActionData = try XCTUnwrap(capturedCustomActionData)
        expect(customActionData.actionIdentifier) == "delete_user"
        expect(customActionData.purchaseIdentifier) == purchaseInformation.productIdentifier
    }

    func testCustomActionPathWithoutActionIdentifier() async throws {
        let purchaseInformation = PurchaseInformation.subscription
        let actionWrapper = CustomerCenterActionWrapper()
        var wasActionTriggered = false

        // Set up expectation that should NOT be fulfilled
        let expectation = XCTestExpectation(description: "Custom action should not be triggered")
        expectation.isInverted = true

        // Monitor the customActionSelected publisher
        actionWrapper
            .onCustomerCenterCustomActionSelected { _, _ in
                wasActionTriggered = true
                expectation.fulfill() // This should not happen
            }
        .store(in: &cancellables)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: Self.managementScreen(refundWindowDuration: .forever),
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Create a custom action path without action identifier
        let customActionPath = CustomerCenterConfigData.HelpPath(
            id: "custom_no_identifier",
            title: "Custom Action",
            type: .customAction,
            detail: nil,
            customActionIdentifier: nil
        )

        // Call handleHelpPath with the custom action - should not trigger action due to missing identifier
        await viewModel.handleHelpPath(customActionPath, withActiveProductId: purchaseInformation.productIdentifier)

        // Wait to ensure no action is triggered
        await fulfillment(of: [expectation], timeout: 0.5)

        // Verify that no custom action was triggered due to missing identifier
        expect(wasActionTriggered) == false
    }

    func testCustomActionPathWithNilActivePurchaseId() async throws {
        let actionWrapper = CustomerCenterActionWrapper()
        var capturedCustomActionData: CustomActionData?

        // Set up expectation to capture custom action
        let expectation = XCTestExpectation(description: "Custom action triggered without purchase ID")

        // Monitor the customActionSelected publisher
        actionWrapper
            .onCustomerCenterCustomActionSelected({ actionIdentifier, purchaseIdentifier in
                capturedCustomActionData = CustomActionData(
                    actionIdentifier: actionIdentifier,
                    purchaseIdentifier: purchaseIdentifier
                )
                expectation.fulfill()
            })
            .store(in: &cancellables)

        let viewModel = BaseManageSubscriptionViewModel(
            screen: Self.managementScreen(refundWindowDuration: .forever),
            actionWrapper: actionWrapper,
            purchaseInformation: nil, // No purchase information
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Create a custom action path
        let customActionPath = CustomerCenterConfigData.HelpPath(
            id: "custom_rate_app",
            title: "Rate App",
            type: .customAction,
            detail: nil,
            customActionIdentifier: "rate_app"
        )

        // Call handleHelpPath without active purchase ID
        await viewModel.handleHelpPath(customActionPath, withActiveProductId: nil)

        // Wait for the action to be triggered
        await fulfillment(of: [expectation], timeout: 1.0)

        // Verify that the custom action was triggered with nil purchase ID
        let customActionData = try XCTUnwrap(capturedCustomActionData)
        expect(customActionData.actionIdentifier) == "rate_app"
        expect(customActionData.purchaseIdentifier).to(beNil())
    }

    // MARK: - Product Type Path Filtering Tests

    func testNonRenewableSubscriptionDoesNotShowCancelPath() {
        let purchase = PurchaseInformation.mock(
            store: .appStore,
            isSubscription: true,
            productType: .nonRenewableSubscription,
            renewalDate: Date().addingTimeInterval(86400) // has renewal date but non-renewable
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        expect(viewModel.relevantPathsForPurchase.count) == 1
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .refundRequest })).to(beTrue())
    }

    func testAutoRenewableSubscriptionShowsCancelPath() {
        let purchase = PurchaseInformation.mock(
            store: .appStore,
            isSubscription: true,
            productType: .autoRenewableSubscription,
            isCancelled: false,
            renewalDate: Date().addingTimeInterval(86400)
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Auto-renewable App Store subscriptions should show cancel path
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beTrue())
    }

    func testNonAppStoreAutoRenewableSubscriptionShowsCancelPath() {
        let purchase = PurchaseInformation.mock(
            store: .playStore,
            isSubscription: true,
            productType: nil, // Non-App Store, so no productType available
            isCancelled: false,
            renewalDate: Date().addingTimeInterval(86400)
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Non-App Store subscriptions should show cancel path (they don't have productType info)
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beTrue())
    }

    func testConsumableProductDoesNotShowCancelPath() {
        let purchase = PurchaseInformation.mock(
            store: .appStore,
            isSubscription: false,
            productType: .consumable,
            isCancelled: false
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Consumable products should not show cancel path
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beFalse())
    }

    func testNonConsumableProductDoesNotShowCancelPath() {
        let purchase = PurchaseInformation.mock(
            store: .appStore,
            isSubscription: false,
            productType: .nonConsumable,
            isCancelled: false
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Non-consumable (lifetime) products should not show cancel path
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .cancel })).to(beFalse())
    }

    func testAutoRenewableSubscriptionDoesNotShowChangePlansIfLifetime() {
        let purchase = PurchaseInformation.mock(
            store: .appStore,
            isSubscription: true,
            productType: .autoRenewableSubscription,
            isLifetime: true
        )

        let viewModel = BaseManageSubscriptionViewModel(
            screen: BaseManageSubscriptionViewModelTests.default,
            actionWrapper: CustomerCenterActionWrapper(),
            purchaseInformation: purchase,
            purchasesProvider: MockCustomerCenterPurchases()
        )

        // Lifetime subscriptions should not show change plans
        expect(viewModel.relevantPathsForPurchase.contains(where: { $0.type == .changePlans })).to(beFalse())
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

#endif
