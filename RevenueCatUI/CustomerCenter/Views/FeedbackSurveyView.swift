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

    @Binding
    private var isPresented: Bool

    init(
        feedbackSurveyData: FeedbackSurveyData,
        customerCenterActionHandler: CustomerCenterActionHandler?,
        isPresented: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: FeedbackSurveyViewModel(
            feedbackSurveyData: feedbackSurveyData,
            customerCenterActionHandler: customerCenterActionHandler
        ))
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            List {
                FeedbackSurveyButtonsView(
                    options: self.viewModel.feedbackSurveyData.configuration.options,
                    onOptionSelected: { option in
                        await self.viewModel.handleAction(
                            for: option,
                            dismissView: self.dismissView
                        )
                    },
                    loadingOption: self.$viewModel.loadingOption
                )
            }
            .sheet(
                item: self.$viewModel.promotionalOfferData,
                content: { promotionalOfferData in
                    PromotionalOfferView(
                        promotionalOffer: promotionalOfferData.promotionalOffer,
                        product: promotionalOfferData.product,
                        promoOfferDetails: promotionalOfferData.promoOfferDetails,
                        onDismissPromotionalOfferView: { userAction in
                            Task(priority: .userInitiated) {
                                await viewModel.handleDismissPromotionalOfferView(
                                    userAction,
                                    dismissView: self.dismissView
                                )
                            }
                        }
                    )
                    .interactiveDismissDisabled()
                })
        }
        .navigationTitle(self.viewModel.feedbackSurveyData.configuration.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dismissView() {
        self.isPresented = false
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
    var loadingOption: String?

    var body: some View {
        ForEach(options, id: \.id) { option in
            AsyncButton {
                await self.onOptionSelected(option)
            } label: {
                if self.loadingOption == option.id {
                    TintedProgressView()
                } else {
                    Text(option.title)
                }
            }
            .disabled(self.loadingOption != nil)
        }

    }

}

#endif
