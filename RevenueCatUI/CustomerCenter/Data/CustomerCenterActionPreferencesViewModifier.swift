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

/// A state container for tracking CustomerCenter events
/// This class lives outside the ViewModifier to ensure state persists across view updates
@available(iOS 15.0, *)
@MainActor class CustomerCenterPreferenceState: ObservableObject {
    @Published var restoreCounter: UUID = UUID()
    @Published var restoreFailed: Error?
    @Published var restoreCompleted: CustomerInfo?
    @Published var showingManageSubscriptions: Bool = false
    @Published var refundRequestStarted: String?
    @Published var refundRequestCompleted: RefundRequestStatus?
    @Published var feedbackSurveyCompleted: String?

    func incrementRestoreCounter() {
        restoreCounter = UUID()
        #if DEBUG
        print("DEBUG: 🔢 Incremented restore counter to: \(restoreCounter)")
        #endif
    }

    func setRestoreFailed(_ error: Error) {
        self.restoreFailed = error
    }

    func setRestoreCompleted(_ info: CustomerInfo) {
        self.restoreCompleted = info
    }

    func setShowingManageSubscriptions() {
        self.showingManageSubscriptions = true
    }

    func setRefundRequestStarted(_ productId: String) {
        self.refundRequestStarted = productId
    }

    func setRefundRequestCompleted(_ status: RefundRequestStatus) {
        self.refundRequestCompleted = status
    }

    func setFeedbackSurveyCompleted(_ optionId: String) {
        self.feedbackSurveyCompleted = optionId
    }
}

/// A view modifier that connects CustomerCenterViewModel actions to the SwiftUI preference system
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterActionPreferencesViewModifier: ViewModifier {

    let actionWrapper: CustomerCenterActionWrapper

    // Use StateObject to ensure the state persists across view updates
    @StateObject private var state = CustomerCenterPreferenceState()

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set up direct binding to the state variables
                actionWrapper.setRestoreStarted = {
                    state.incrementRestoreCounter()
                }

                actionWrapper.setRestoreFailed = { error in
                    state.setRestoreFailed(error)
                }

                actionWrapper.setRestoreCompleted = { info in
                    state.setRestoreCompleted(info)
                }

                actionWrapper.setShowingManageSubscriptions = {
                    state.setShowingManageSubscriptions()
                }

                actionWrapper.setRefundRequestStarted = { productId in
                    state.setRefundRequestStarted(productId)
                }

                actionWrapper.setRefundRequestCompleted = { status in
                    state.setRefundRequestCompleted(status)
                }

                actionWrapper.setFeedbackSurveyCompleted = { optionId in
                    state.setFeedbackSurveyCompleted(optionId)
                }
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterView.RestoreFailedPreferenceKey.self,
                        value: state.restoreFailed as NSError?)
            .preference(key: CustomerCenterView.RestoreCompletedPreferenceKey.self,
                        value: state.restoreCompleted)
            .preference(key: CustomerCenterView.ShowingManageSubscriptionsPreferenceKey.self,
                        value: state.showingManageSubscriptions)
            .preference(key: CustomerCenterView.RefundRequestStartedPreferenceKey.self,
                        value: state.refundRequestStarted)
            .preference(key: CustomerCenterView.RefundRequestCompletedPreferenceKey.self,
                        value: state.refundRequestCompleted)
            .preference(key: CustomerCenterView.FeedbackSurveyCompletedPreferenceKey.self,
                        value: state.feedbackSurveyCompleted)
    }
}

#endif
