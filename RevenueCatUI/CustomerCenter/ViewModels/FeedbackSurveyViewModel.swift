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
    var loadingState: String?
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

    func handleAction(for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async {
        if let customerCenterActionHandler = self.customerCenterActionHandler {
            customerCenterActionHandler(.feedbackSurveyCompleted(option.id))
        }

        if let promotionalOffer = option.promotionalOffer,
           promotionalOffer.eligible {
            self.loadingState = option.id
            let result = await loadPromotionalOfferUseCase.execute(promoOfferDetails: promotionalOffer)
            switch result {
            case .success(let promotionalOfferData):
                self.promotionalOfferData = promotionalOfferData
            case .failure:
                self.feedbackSurveyData.onOptionSelected()
                self.loadingState = nil
            }
        } else {
            self.feedbackSurveyData.onOptionSelected()
        }
    }

    func handleSheetDismiss() {
        self.feedbackSurveyData.onOptionSelected()
        self.loadingState = nil
    }

}

#endif
