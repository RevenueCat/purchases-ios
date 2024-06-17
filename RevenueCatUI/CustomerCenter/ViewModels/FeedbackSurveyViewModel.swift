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

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class FeedbackSurveyViewModel: ObservableObject {

    @Published
    var feedbackSurveyData: FeedbackSurveyData
    @Published
    var isShowingPromotionalOffer: Bool = false
    @Published
    var selectedPromotionalOffer: CustomerCenterConfigData.HelpPath.PromotionalOffer?

    init(feedbackSurveyData: FeedbackSurveyData) {
        self.feedbackSurveyData = feedbackSurveyData
    }

    func handleAction(for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) {
        if let promotionalOffer = option.promotionalOffer {
            applyPromotionalOffer(promotionalOffer)
        } else {
            feedbackSurveyData.action()
        }
    }

    private func applyPromotionalOffer(_ offer: CustomerCenterConfigData.HelpPath.PromotionalOffer) {
        selectedPromotionalOffer = offer
        isShowingPromotionalOffer = true
    }

}

#endif
