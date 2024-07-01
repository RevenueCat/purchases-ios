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

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct FeedbackSurveyView: View {

    @StateObject
    private var viewModel: FeedbackSurveyViewModel
    private let appearance: CustomerCenterConfigData.Appearance

    init(feedbackSurveyData: FeedbackSurveyData,
         appearance: CustomerCenterConfigData.Appearance) {
        self._viewModel = StateObject(wrappedValue: FeedbackSurveyViewModel(feedbackSurveyData: feedbackSurveyData))
        self.appearance = appearance
    }

    var body: some View {
        VStack {
            Text(self.viewModel.feedbackSurveyData.configuration.title)
                .font(.title)
                .padding()

            Spacer()

            FeedbackSurveyButtonsView(options: self.viewModel.feedbackSurveyData.configuration.options,
                                      action: self.viewModel.handleAction(for:),
                                      appearance: self.appearance,
                                      loadingStates: self.$viewModel.loadingStates)
        }
        .sheet(
            isPresented: self.$viewModel.isShowingPromotionalOffer,
            onDismiss: { self.viewModel.handleSheetDismiss() },
            content: {
                if let promotionalOffer = self.viewModel.promotionalOffer,
                   let product = self.viewModel.product {
                    PromotionalOfferView(promotionalOffer: promotionalOffer,
                                         product: product,
                                         appearance: self.appearance)
                }
            })
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct FeedbackSurveyButtonsView: View {

    let options: [CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option]
    let action: (CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async -> Void
    let appearance: CustomerCenterConfigData.Appearance

    @Binding
    var loadingStates: [String: Bool]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(options, id: \.id) { option in
                Button {
                    Task {
                        await self.action(option)
                    }
                } label: {
                    if self.loadingStates[option.id] ?? false {
                        ProgressView()
                    } else {
                        Text(option.title)
                    }
                }
                .buttonStyle(ManageSubscriptionsButtonStyle(appearance: appearance))
                .disabled(self.loadingStates[option.id] ?? false)
            }
        }
    }

}

#endif
