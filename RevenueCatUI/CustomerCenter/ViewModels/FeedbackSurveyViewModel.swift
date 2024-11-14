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

    deinit {
        print("DEINIT CALLED")
    }

    func handleAction(for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async {
        if let customerCenterActionHandler = self.customerCenterActionHandler {
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
    func handleDismissPromotionalOfferView(_ userAction: PromotionalOfferView.PromotionalOfferViewAction) async {
        // Clear the promotional offer data to dismiss the sheet
        self.promotionalOfferData = nil

        switch userAction {
        case .successfullyRedeemedPromotionalOffer(let purchaseResultData):
            // The user redeemed a Promotional Offer, so we want to return out of the current flow
            break
        case .promotionalCodeRedemptionFailed, .declinePromotionalOffer:
            // Continue with the existing path's flow
            self.feedbackSurveyData.onOptionSelected()
        }
    }
}

#endif
