//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeedbackSurveyViewModelTests.swift
//
//  Created by Cesar de la Vega on 10/2/25.

// swiftlint:disable type_body_length file_length

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class FeedbackSurveyViewModelTests: TestCase {

    let mockLoadPromotionalOfferUseCase = MockLoadPromotionalOfferUseCase()
    let mockPurchases = MockCustomerCenterPurchases()

    func testInitialState() {
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: Self.path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(feedbackSurveyData: data,
                                                purchasesProvider: MockCustomerCenterPurchases(),
                                                actionWrapper: CustomerCenterActionWrapper())

        expect(viewModel.feedbackSurveyData).to(equal(data))
    }

    func testHandleActionWithoutPromotionalOfferDismissesView() async {
        let option = Self.option

        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: Self.path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper()
        )

        let dismissViewExpectation = expectation(description: "Dismiss view should be called")

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen) {
            dismissViewExpectation.fulfill()
        }

        await fulfillment(of: [dismissViewExpectation], timeout: 1.0)
    }

    func testHandleActionWithoutPromotionalDoesNotSetLoadingOption() async {
        let option = Self.option

        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: Self.path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen) {
        }

        expect(viewModel.loadingOption).to(beNil())
    }

    func testHandleActionWithoutPromotionalOfferTriggersOnOptionSelectedCallback() async {
        let option = Self.option

        let onOptionSelectedExpectation = expectation(description: "OnOptionSelected should be called")

        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: Self.path,
            onOptionSelected: {
                onOptionSelectedExpectation.fulfill()
            }
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen) {
        }

        await fulfillment(of: [onOptionSelectedExpectation], timeout: 1.0)
    }

    func testHandleActionWithoutPromotionalOfferAndNoCustomerCenterActionHandlerTracksEvent() async throws {
        let option = Self.option
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(self.mockPurchases.trackCallCount) == 1
        let event = try XCTUnwrap(self.mockPurchases.trackedEvents.first)
        expect(event.type) == .answerSubmitted
        let data = try XCTUnwrap(event.answerSubmittedData)
        expect(data.localeIdentifier) == "en_US"
        expect(data.darkMode) == false
        expect(data.isSandbox) == mockPurchases.isSandbox
        expect(data.displayMode) == RevenueCat.CustomerCenterPresentationMode.fullScreen
        expect(data.revisionID) == 0
        expect(data.additionalContext).to(beNil())
        expect(data.path) == .cancel
        expect(data.surveyOptionID) == option.id
        expect(data.url).to(beNil())
    }

    func testHandleActionWithoutPromotionalOfferTracksEvent() async throws {
        let option = Self.option
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { _ in })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(self.mockPurchases.trackCallCount) == 1
        let event = try XCTUnwrap(self.mockPurchases.trackedEvents.first)
        expect(event.type) == .answerSubmitted
        let data = try XCTUnwrap(event.answerSubmittedData)
        expect(data.localeIdentifier) == "en_US"
        expect(data.darkMode) == false
        expect(data.isSandbox) == mockPurchases.isSandbox
        expect(data.displayMode) == RevenueCat.CustomerCenterPresentationMode.fullScreen
        expect(data.revisionID) == 0
        expect(data.additionalContext).to(beNil())
        expect(data.path) == .cancel
        expect(data.surveyOptionID) == option.id
        expect(data.url).to(beNil())
    }

    func testHandleActionWithoutPromotionalOfferCallsHandler() async throws {
        let option = Self.option
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let handlerCalledExpectation = expectation(description: "customerCenterActionHandler should be called")
        var optionCalled: String?
        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { action in
                switch action {
                case .feedbackSurveyCompleted(let option):
                    handlerCalledExpectation.fulfill()
                    optionCalled = option
                default:
                    return
                }
            })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        await fulfillment(of: [handlerCalledExpectation], timeout: 1.0)
        expect(optionCalled) == option.id
    }

    func testHandleActionWithPromotionalOfferTracksEvent() async throws {
        let option = Self.optionWithPromo
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { _ in })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(self.mockPurchases.trackCallCount) == 1
        let event = try XCTUnwrap(self.mockPurchases.trackedEvents.first)
        expect(event.type) == .answerSubmitted
        let data = try XCTUnwrap(event.answerSubmittedData)
        expect(data.localeIdentifier) == "en_US"
        expect(data.darkMode) == false
        expect(data.isSandbox) == mockPurchases.isSandbox
        expect(data.displayMode) == RevenueCat.CustomerCenterPresentationMode.fullScreen
        expect(data.revisionID) == 0
        expect(data.additionalContext).to(beNil())
        expect(data.path) == .cancel
        expect(data.surveyOptionID) == option.id
        expect(data.url).to(beNil())
    }

    func testHandleActionWithPromotionalOfferAndNoCustomerCenterActionHandlerTracksEvent() async throws {
        let option = Self.optionWithPromo
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper()
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(self.mockPurchases.trackCallCount) == 1
        let event = try XCTUnwrap(self.mockPurchases.trackedEvents.first)
        expect(event.type) == .answerSubmitted
        let data = try XCTUnwrap(event.answerSubmittedData)
        expect(data.localeIdentifier) == "en_US"
        expect(data.darkMode) == false
        expect(data.isSandbox) == mockPurchases.isSandbox
        expect(data.displayMode) == RevenueCat.CustomerCenterPresentationMode.fullScreen
        expect(data.revisionID) == 0
        expect(data.additionalContext).to(beNil())
        expect(data.path) == .cancel
        expect(data.surveyOptionID) == option.id
        expect(data.url).to(beNil())
    }

    func testHandleActionWithPromotionalOfferCallsHandler() async throws {
        let option = Self.optionWithPromo
        let path = Self.path
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {}
        )

        let handlerCalledExpectation = expectation(description: "customerCenterActionHandler should be called")
        var optionCalled: String?
        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { action in
                switch action {
                case .feedbackSurveyCompleted(let option):
                    handlerCalledExpectation.fulfill()
                    optionCalled = option
                default:
                    return
                }
            })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        await fulfillment(of: [handlerCalledExpectation], timeout: 1.0)
        expect(optionCalled) == option.id
    }

    func testHandleActionWithPromotionalOfferLoadsPromotionalOfferAndDoesNotTriggerMainAction() async throws {
        let option = Self.optionWithPromo
        let path = Self.path
        var optionCalled: Bool = false
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {
                optionCalled = true
            }
        )

        mockLoadPromotionalOfferUseCase.mockedProduct = Self.product
        mockLoadPromotionalOfferUseCase.mockedPromoOfferDetails = Self.promoOfferDetails
        let signedData = PromotionalOffer.SignedData(
            identifier: "id",
            keyIdentifier: "key_i",
            nonce: UUID(),
            signature: "a signature",
            timestamp: 1234
        )
        let discount = MockStoreProductDiscount(
            offerIdentifier: "offer_id",
            currencyCode: "usd",
            price: 1,
            localizedPriceString: "$1.00",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        mockLoadPromotionalOfferUseCase.mockedPromotionalOffer = PromotionalOffer(
            discount: discount,
            signedData: signedData
        )
        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { _ in })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(optionCalled).to(beFalse())
    }

    func testHandleActionWithPromotionalOfferTriggersMainActionIfLoadingFails() async throws {
        let option = Self.optionWithPromo
        let path = Self.path
        var optionCalled: Bool = false
        let data = FeedbackSurveyData(
            productIdentifier: "",
            configuration: Self.feedbackSurvey,
            path: path,
            onOptionSelected: {
                optionCalled = true
            }
        )

        mockLoadPromotionalOfferUseCase.mockedProduct = Self.product
        mockLoadPromotionalOfferUseCase.mockedPromoOfferDetails = Self.promoOfferDetails
        mockLoadPromotionalOfferUseCase.mockedPromotionalOffer = nil

        let viewModel = FeedbackSurveyViewModel(
            feedbackSurveyData: data,
            purchasesProvider: mockPurchases,
            loadPromotionalOfferUseCase: mockLoadPromotionalOfferUseCase,
            actionWrapper: CustomerCenterActionWrapper(legacyActionHandler: { _ in })
        )

        await viewModel.handleAction(for: option,
                                     darkMode: false,
                                     displayMode: CustomerCenterPresentationMode.fullScreen,
                                     locale: Locale(identifier: "en_US")) {
        }

        expect(optionCalled).to(beTrue())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension FeedbackSurveyViewModelTests {

    static let promoOfferDetails = CustomerCenterConfigData.HelpPath.PromotionalOffer(
        iosOfferId: "offer_id",
        eligible: true,
        title: "Wait",
        subtitle: "Here's an offer for you",
        productMapping: [
            "product_id": "offer_id"
        ]
    )

    static let product = PurchaseInformationFixtures.product(
        id: "product_id",
        title: "yearly",
        duration: .year,
        price: Decimal(29.99),
        offerIdentifier: "offer_id"
    )

    static let option = CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option(
        id: "1",
        title: "Too expensive",
        promotionalOffer: nil
    )

    static let optionWithPromo = CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option(
        id: "2",
        title: "No too expensive",
        promotionalOffer: CustomerCenterConfigData.HelpPath.PromotionalOffer(
            iosOfferId: "offer_id",
            eligible: true,
            title: "title",
            subtitle: "subtitle",
            productMapping: ["monthly": "offer_id"]
        )
    )

    static let feedbackSurvey = CustomerCenterConfigData.HelpPath.FeedbackSurvey(
        title: "Why are you cancelling?",
        options: [
            option,
            optionWithPromo,
            .init(
                id: "3",
                title: "Bought by mistake",
                promotionalOffer: nil
            )
        ]
    )

    static let path = CustomerCenterConfigData.HelpPath(
        id: "4",
        title: "Cancel subscription",
        url: nil,
        openMethod: nil,
        type: .cancel,
        detail: .feedbackSurvey(feedbackSurvey),
        refundWindowDuration: .forever)

}

#endif
