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

    private(set) var localization: CustomerCenterConfigData.Localization

    private var purchasesProvider: CustomerCenterPurchasesType
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType

    convenience init(feedbackSurveyData: FeedbackSurveyData,
                     localization: CustomerCenterConfigData.Localization) {
        self.init(feedbackSurveyData: feedbackSurveyData,
                  localization: localization,
                  purchasesProvider: CustomerCenterPurchases(),
                  loadPromotionalOfferUseCase: LoadPromotionalOfferUseCase())
    }

    init(feedbackSurveyData: FeedbackSurveyData,
         localization: CustomerCenterConfigData.Localization,
         purchasesProvider: CustomerCenterPurchasesType,
         loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType) {
        self.feedbackSurveyData = feedbackSurveyData
        self.localization = localization
        self.purchasesProvider = purchasesProvider
        self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase
    }

    func handleAction(for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async {
        if let promotionalOffer = option.promotionalOffer {
            self.loadingState = option.id
            let result = await loadPromotionalOfferUseCase.execute(promoOfferDetails: promotionalOffer)
            switch result {
            case .success(let promotionalOfferData):
                self.promotionalOfferData = promotionalOfferData
            case .failure(let error):
                self.feedbackSurveyData.action()
            }
        } else {
            self.feedbackSurveyData.action()
        }
    }

    func handleSheetDismiss() {
        self.feedbackSurveyData.action()
        self.loadingState = nil
    }

}

#endif
