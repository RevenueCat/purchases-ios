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

    @ObservedObject
    var feedbackSurveyData: FeedbackSurveyData

    var body: some View {
        VStack {
            Text(feedbackSurveyData.configuration.title)
                .font(.title)
                .padding()

            Spacer()

            FeedbackSurveyButtonsView(options: feedbackSurveyData.configuration.options, 
                                      action: feedbackSurveyData.action)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct FeedbackSurveyButtonsView: View {

    let options: [CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option]
    let action: (() -> Void)

    var body: some View {
        VStack(spacing: 16) {
            ForEach(options, id: \.id) { option in
                Button(option.title) {
                    Task {
                        self.action()
                    }
                }
                .buttonStyle(ManageSubscriptionsButtonStyle())
            }
        }
    }

}

#endif
