//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterActionPreferenceConnector.swift
//  
//  Created by Cesar de la Vega on 2024-06-17.

import RevenueCat
import SwiftUI

#if os(iOS)

/// A view modifier that connects CustomerCenterViewModel actions to the SwiftUI preference system
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterActionPreferenceConnector: ViewModifier {

    @ObservedObject var viewModel: CustomerCenterViewModel

    // State to track preferences that should be set
    @State private var restoreStarted: Bool = false
    @State private var restoreFailed: Error?
    @State private var restoreCompleted: CustomerInfo?
    @State private var showingManageSubscriptions: Bool = false
    @State private var refundRequestStarted: String?
    @State private var refundRequestCompleted: RefundRequestStatus?
    @State private var feedbackSurveyCompleted: String?

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set up direct binding to the state variables
                viewModel.actionBridge.setRestoreStarted = { restoreStarted = true }
                viewModel.actionBridge.setRestoreFailed = { restoreFailed = $0 as NSError }
                viewModel.actionBridge.setRestoreCompleted = { restoreCompleted = $0 }
                viewModel.actionBridge.setShowingManageSubscriptions = { showingManageSubscriptions = true }
                viewModel.actionBridge.setRefundRequestStarted = { refundRequestStarted = $0 }
                viewModel.actionBridge.setRefundRequestCompleted = { refundRequestCompleted = $0 }
                viewModel.actionBridge.setFeedbackSurveyCompleted = { feedbackSurveyCompleted = $0 }
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterRestoreStartedPreferenceKey.self,
                        value: restoreStarted)
            .preference(key: CustomerCenterRestoreFailedPreferenceKey.self,
                        value: restoreFailed as NSError?)
            .preference(key: CustomerCenterRestoreCompletedPreferenceKey.self,
                        value: restoreCompleted)
            .preference(key: CustomerCenterShowingManageSubscriptionsPreferenceKey.self,
                        value: showingManageSubscriptions)
            .preference(key: CustomerCenterRefundRequestStartedPreferenceKey.self,
                        value: refundRequestStarted)
            .preference(key: CustomerCenterRefundRequestCompletedPreferenceKey.self,
                        value: refundRequestCompleted)
            .preference(key: CustomerCenterFeedbackSurveyCompletedPreferenceKey.self,
                        value: feedbackSurveyCompleted)
    }
}

#endif
