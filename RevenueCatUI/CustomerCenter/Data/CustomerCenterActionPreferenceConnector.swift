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

    let actionBridge: CustomerCenterActionBridge

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
                actionBridge.setRestoreStarted = { restoreStarted = true }
                actionBridge.setRestoreFailed = { restoreFailed = $0 as NSError }
                actionBridge.setRestoreCompleted = { restoreCompleted = $0 }
                actionBridge.setShowingManageSubscriptions = { showingManageSubscriptions = true }
                actionBridge.setRefundRequestStarted = { refundRequestStarted = $0 }
                actionBridge.setRefundRequestCompleted = { refundRequestCompleted = $0 }
                actionBridge.setFeedbackSurveyCompleted = { feedbackSurveyCompleted = $0 }
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterView.RestoreStartedPreferenceKey.self,
                        value: restoreStarted)
            .preference(key: CustomerCenterView.RestoreFailedPreferenceKey.self,
                        value: restoreFailed as NSError?)
            .preference(key: CustomerCenterView.RestoreCompletedPreferenceKey.self,
                        value: restoreCompleted)
            .preference(key: CustomerCenterView.ShowingManageSubscriptionsPreferenceKey.self,
                        value: showingManageSubscriptions)
            .preference(key: CustomerCenterView.RefundRequestStartedPreferenceKey.self,
                        value: refundRequestStarted)
            .preference(key: CustomerCenterView.RefundRequestCompletedPreferenceKey.self,
                        value: refundRequestCompleted)
            .preference(key: CustomerCenterView.FeedbackSurveyCompletedPreferenceKey.self,
                        value: feedbackSurveyCompleted)
    }
}

#endif
