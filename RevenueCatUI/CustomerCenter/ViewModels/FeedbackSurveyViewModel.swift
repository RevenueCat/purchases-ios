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

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    @Published
    var feedbackSurveyData: FeedbackSurveyData
    @Published
    var isShowingPromotionalOffer: Bool = false
    @Published
    var loadingStates: [String: Bool] = [:]

    var promotionalOffer: PromotionalOffer? {
        return promotionalOfferViewModel.promotionalOffer
    }

    var product: StoreProduct? {
        return promotionalOfferViewModel.product
    }

    private var customerInfoFetcher: CustomerInfoFetcher
    private var promotionalOfferViewModel: PromotionalOfferViewModel

    convenience init(feedbackSurveyData: FeedbackSurveyData) {
        self.init(feedbackSurveyData: feedbackSurveyData,
                  promotionalOfferViewModel: PromotionalOfferViewModel(),
                  customerInfoFetcher: {
            guard Purchases.isConfigured else {
                throw PaywallError.purchasesNotConfigured
            }

            return try await Purchases.shared.customerInfo()
        })
    }

    // @PublicForExternalTesting
    init(feedbackSurveyData: FeedbackSurveyData,
         promotionalOfferViewModel: PromotionalOfferViewModel,
         customerInfoFetcher: @escaping CustomerInfoFetcher) {
        self.feedbackSurveyData = feedbackSurveyData
        self.promotionalOfferViewModel = promotionalOfferViewModel
        self.customerInfoFetcher = customerInfoFetcher
    }

    func handleAction(for option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async {
        if let promotionalOffer = option.promotionalOffer {
            self.loadingStates[option.id] = true
            await promotionalOfferViewModel.loadPromo(promotionalOfferId: promotionalOffer.iosOfferId)
            self.isShowingPromotionalOffer = true
        } else {
            self.feedbackSurveyData.action()
        }
    }

    func handleSheetDismiss() {
        self.feedbackSurveyData.action()
        self.loadingStates.removeAll()
    }

}

#endif
