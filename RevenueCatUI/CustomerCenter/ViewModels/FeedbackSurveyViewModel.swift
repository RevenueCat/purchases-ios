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
import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class FeedbackSurveyViewModel: ObservableObject {

    var feedbackSurveyData: FeedbackSurveyData

    @Published
    var loadingOption: String?

    @Published
    var promotionalOfferData: PromotionalOfferData?

    private var purchasesProvider: CustomerCenterPurchasesType
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType
    private let customerCenterActionHandler: CustomerCenterActionHandler?

    convenience init(feedbackSurveyData: FeedbackSurveyData,
                     customerCenterActionHandler: CustomerCenterActionHandler?) {
        self.init(feedbackSurveyData: feedbackSurveyData,
                  purchasesProvider: CustomerCenterPurchases(),
                  loadPromotionalOfferUseCase: LoadPromotionalOfferUseCase(),
                  customerCenterActionHandler: customerCenterActionHandler)
    }

    init(feedbackSurveyData: FeedbackSurveyData,
         purchasesProvider: CustomerCenterPurchasesType,
         loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType,
         customerCenterActionHandler: CustomerCenterActionHandler?) {
        self.feedbackSurveyData = feedbackSurveyData
        self.purchasesProvider = purchasesProvider
        self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase
        self.customerCenterActionHandler = customerCenterActionHandler
    }

    func handleAction(
        for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option,
        darkMode: Bool,
        displayMode: CustomerCenterPresentationMode,
        dismissView: () -> Void
    ) async {
        if let customerCenterActionHandler = self.customerCenterActionHandler {
            trackSurveyAnswerSubmitted(option: option, darkMode: darkMode, displayMode: displayMode)
            customerCenterActionHandler(.feedbackSurveyCompleted(option.id))
        }

        if let promotionalOffer = option.promotionalOffer,
           promotionalOffer.eligible {
            self.loadingOption = option.id
            let result = await loadPromotionalOfferUseCase.execute(promoOfferDetails: promotionalOffer)
            switch result {
            case .success(let promotionalOfferData):
                self.promotionalOfferData = promotionalOfferData
            case .failure:
                self.feedbackSurveyData.onOptionSelected()
                self.loadingOption = nil
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
        // Clear the promotional offer data to dismiss the sheet
        self.promotionalOfferData = nil
        self.loadingOption = nil

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
                                    displayMode: CustomerCenterPresentationMode) {
        let isSandbox = purchasesProvider.isSandbox
        let surveyOptionData = CustomerCenterAnswerSubmittedEvent.Data(locale: .current,
                                                                       darkMode: darkMode,
                                                                       isSandbox: isSandbox,
                                                                       displayMode: displayMode,
                                                                       path: feedbackSurveyData.path.type,
                                                                       url: feedbackSurveyData.path.url,
                                                                       surveyOptionID: option.id,
                                                                       surveyOptionTitleKey: option.title,
                                                                       additionalContext: nil,
                                                                       revisionID: 0)
        let event = CustomerCenterAnswerSubmittedEvent.answerSubmitted(CustomerCenterEventCreationData(),
                                                                       surveyOptionData)
        purchasesProvider.track(customerCenterEvent: event)
    }

}

#endif
