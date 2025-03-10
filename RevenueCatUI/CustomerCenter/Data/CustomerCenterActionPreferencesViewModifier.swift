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

/// A wrapper that makes any value unique by including a UUID
struct UniqueWrapper<T> {
    let id = UUID()
    let value: T
}

extension UniqueWrapper: Equatable where T: Equatable {
    static func == (lhs: UniqueWrapper<T>, rhs: UniqueWrapper<T>) -> Bool {
        lhs.id == rhs.id
    }
}

/// A view modifier that connects CustomerCenterViewModel actions to the SwiftUI preference system
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterActionPreferencesViewModifier: ViewModifier {

    let actionWrapper: CustomerCenterActionWrapper

    // Use counter to track restore events instead of boolean flag
    // Each increment creates a unique restore event
    @State private var restoreStarted: UniqueWrapper<Bool> = .init(value: false)
    @State private var restoreFailed: UniqueWrapper<NSError>?
    @State private var restoreCompleted: UniqueWrapper<CustomerInfo>?
    // Counter for manage subscriptions to ensure unique values
    @State private var showingManageSubscriptions: UniqueWrapper<Bool> = .init(value: false)
    @State private var refundRequestStarted: UniqueWrapper<String>?
    @State private var refundRequestCompleted: UniqueWrapper<RefundRequestStatus>?
    @State private var feedbackSurveyCompleted: UniqueWrapper<String>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set up direct binding to the state variables
                actionWrapper.setRestoreStarted = {
                    restoreStarted = UniqueWrapper(value: true)
                }
                
                actionWrapper.setRestoreFailed = { error in
                    restoreFailed = UniqueWrapper(value: error as NSError)
                }
                
                actionWrapper.setRestoreCompleted = { info in
                    restoreCompleted = UniqueWrapper(value: info)
                }
                
                actionWrapper.setShowingManageSubscriptions = { 
                    showingManageSubscriptions = UniqueWrapper(value: true)
                }
                
                actionWrapper.setRefundRequestStarted = { productId in
                    refundRequestStarted = UniqueWrapper(value: productId)
                }
                
                actionWrapper.setRefundRequestCompleted = { status in
                    refundRequestCompleted = UniqueWrapper(value: status)
                }
                
                actionWrapper.setFeedbackSurveyCompleted = { reason in
                    feedbackSurveyCompleted = UniqueWrapper(value: reason)
                }
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterView.RestoreStartedPreferenceKey.self,
                        value: restoreStarted)
            .preference(key: CustomerCenterView.RestoreFailedPreferenceKey.self,
                        value: restoreFailed)
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
