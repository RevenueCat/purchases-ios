//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeedbackSurveyView.swift
//
//
//  Created by Cesar de la Vega on 12/6/24.
//

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FeedbackSurveyView: View {

    @StateObject
    private var viewModel: FeedbackSurveyViewModel
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme

    init(feedbackSurveyData: FeedbackSurveyData) {
        let viewModel = FeedbackSurveyViewModel(feedbackSurveyData: feedbackSurveyData)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            if let background = Color.from(colorInformation: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }

            List {
                FeedbackSurveyButtonsView(options: self.viewModel.feedbackSurveyData.configuration.options,
                                          onOptionSelected: self.viewModel.handleAction(for:),
                                          loadingState: self.$viewModel.loadingState)
            }
            .sheet(
                item: self.$viewModel.promotionalOfferData,
                onDismiss: { self.viewModel.handleSheetDismiss() },
                content: { promotionalOfferData in
                    PromotionalOfferView(promotionalOffer: promotionalOfferData.promotionalOffer,
                                         product: promotionalOfferData.product,
                                         promoOfferDetails: promotionalOfferData.promoOfferDetails)
                })
        }
        .navigationTitle(self.viewModel.feedbackSurveyData.configuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FeedbackSurveyButtonsView: View {

    let options: [CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option]
    let onOptionSelected: (_ optionSelected: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async -> Void

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance

    @Binding
    var loadingState: String?

    var body: some View {
        ForEach(options, id: \.id) { option in
            AsyncButton {
                await self.onOptionSelected(option)
            } label: {
                if self.loadingState == option.id {
                    TintedProgressView()
                } else {
                    Text(option.title)
                }
            }
            .disabled(self.loadingState != nil)
        }

    }

}

#endif

#endif
