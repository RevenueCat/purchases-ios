//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeedbackSurveyViewModel.swift
//
//
//  Created by Cesar de la Vega on 17/6/24.
//

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class FeedbackSurveyViewModel: ObservableObject {

    let feedbackSurveyData: FeedbackSurveyData

    @Published
    var loadingOption: String?

    @Published
    var promotionalOfferData: PromotionalOfferData?

    private(set) var purchasesProvider: CustomerCenterPurchasesType
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType
    let actionWrapper: CustomerCenterActionWrapper

    convenience init(feedbackSurveyData: FeedbackSurveyData,
                     purchasesProvider: CustomerCenterPurchasesType,
                     actionWrapper: CustomerCenterActionWrapper) {
        self.init(feedbackSurveyData: feedbackSurveyData,
                  purchasesProvider: purchasesProvider,
                  loadPromotionalOfferUseCase: LoadPromotionalOfferUseCase(purchasesProvider: purchasesProvider),
                  actionWrapper: actionWrapper)
    }

    init(feedbackSurveyData: FeedbackSurveyData,
         purchasesProvider: CustomerCenterPurchasesType,
         loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType,
         actionWrapper: CustomerCenterActionWrapper) {
        self.feedbackSurveyData = feedbackSurveyData
        self.purchasesProvider = purchasesProvider
        self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase
        self.actionWrapper = actionWrapper
    }

    func handleAction(
        for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option,
        darkMode: Bool,
        displayMode: CustomerCenterPresentationMode,
        locale: Locale = .current,
        dismissView: () -> Void
    ) async {
        trackSurveyAnswerSubmitted(option: option, darkMode: darkMode, displayMode: displayMode, locale: locale)

        self.actionWrapper.handleAction(.feedbackSurveyCompleted(option.id))

        if let promotionalOffer = option.promotionalOffer,
           promotionalOffer.eligible {
            self.loadingOption = option.id
            let result = await loadPromotionalOfferUseCase.execute(
                promoOfferDetails: promotionalOffer,
                forProductId: feedbackSurveyData.productIdentifier
            )
            self.loadingOption = nil
            switch result {
            case .success(let promotionalOfferData):
                self.promotionalOfferData = promotionalOfferData
            case .failure:
                self.feedbackSurveyData.onOptionSelected()
                dismissView()
            }
        } else {
            self.feedbackSurveyData.onOptionSelected()
            dismissView()
        }
    }
}

// MARK: - Promotional Offer Sheet Dismissal Handling
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension FeedbackSurveyViewModel {

    /// Function responsible for handling the user's action on the PromotionalOfferView
    func handleDismissPromotionalOfferView(
        _ userAction: PromotionalOfferViewAction,
        dismissView: () -> Void
    ) async {
        if !userAction.shouldTerminateCurrentPathFlow {
            self.feedbackSurveyData.onOptionSelected()
        }

        dismissView()
    }
}

// MARK: - Events
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension FeedbackSurveyViewModel {

    func trackSurveyAnswerSubmitted(option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option,
                                    darkMode: Bool,
                                    displayMode: CustomerCenterPresentationMode,
                                    locale: Locale) {
        let isSandbox = purchasesProvider.isSandbox
        let surveyOptionData = CustomerCenterAnswerSubmittedEvent.Data(locale: locale,
                                                                       darkMode: darkMode,
                                                                       isSandbox: isSandbox,
                                                                       displayMode: displayMode,
                                                                       path: feedbackSurveyData.path.type,
                                                                       url: feedbackSurveyData.path.url,
                                                                       surveyOptionID: option.id,
                                                                       additionalContext: nil,
                                                                       revisionID: 0)
        let event = CustomerCenterAnswerSubmittedEvent.answerSubmitted(CustomerCenterEventCreationData(),
                                                                       surveyOptionData)
        purchasesProvider.track(customerCenterEvent: event)
    }

}

#endif
