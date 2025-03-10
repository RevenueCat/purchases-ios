//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterActionPreferencesViewModifier.swift
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
struct CustomerCenterActionPreferencesViewModifier: ViewModifier {

    let actionWrapper: CustomerCenterActionWrapper

    // Use counter to track restore events instead of boolean flag
    // Each increment creates a unique restore event
    @State private var restoreCounter: Int = 0
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
                actionWrapper.setRestoreStarted = { 
                    // Increment counter to create a new unique value
                    // This guarantees preference change detection
                    restoreCounter += 1
                }
                
                actionWrapper.setRestoreFailed = { error in
                    restoreFailed = error as NSError
                }
                
                actionWrapper.setRestoreCompleted = { info in
                    restoreCompleted = info
                }
                
                actionWrapper.setShowingManageSubscriptions = { showingManageSubscriptions = true }
                actionWrapper.setRefundRequestStarted = { refundRequestStarted = $0 }
                actionWrapper.setRefundRequestCompleted = { refundRequestCompleted = $0 }
                actionWrapper.setFeedbackSurveyCompleted = { feedbackSurveyCompleted = $0 }
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterView.RestoreCounterPreferenceKey.self,
                        value: restoreCounter)
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
