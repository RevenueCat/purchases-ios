//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewModelPreferenceKey.swift
//  
//  Created by Cesar de la Vega on 2024-06-17.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Internal method to set a preference flag for restore started
    @MainActor
    func setRestoreStarted() -> some View {
        self.preference(key: CustomerCenterRestoreStartedPreferenceKey.self, value: true)
    }

    /// Internal method to set a preference value for restore failed
    @MainActor
    func setRestoreFailed(_ error: Error) -> some View {
        self.preference(key: CustomerCenterRestoreFailedPreferenceKey.self, value: error)
    }

    /// Internal method to set a preference value for restore completed
    @MainActor
    func setRestoreCompleted(_ customerInfo: CustomerInfo) -> some View {
        self.preference(key: CustomerCenterRestoreCompletedPreferenceKey.self, value: customerInfo)
    }

    /// Internal method to set a preference flag for showing manage subscriptions
    @MainActor
    func setShowingManageSubscriptions() -> some View {
        self.preference(key: CustomerCenterShowingManageSubscriptionsPreferenceKey.self, value: true)
    }

    /// Internal method to set a preference value for refund request started
    @MainActor
    func setRefundRequestStarted(_ productId: String) -> some View {
        self.preference(key: CustomerCenterRefundRequestStartedPreferenceKey.self, value: productId)
    }

    /// Internal method to set a preference value for refund request completed
    @MainActor
    func setRefundRequestCompleted(_ status: RefundRequestStatus) -> some View {
        self.preference(key: CustomerCenterRefundRequestCompletedPreferenceKey.self, value: status)
    }

    /// Internal method to set a preference value for feedback survey completed
    @MainActor
    func setFeedbackSurveyCompleted(_ optionId: String) -> some View {
        self.preference(key: CustomerCenterFeedbackSurveyCompletedPreferenceKey.self, value: optionId)
    }
}

/// Helper class that bridges the CustomerCenterActionHandler to the new preference-based system
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class CustomerCenterActionBridge {

    private let customerCenterActionHandler: CustomerCenterActionHandler?

    // Direct setter closures that will be set by the preference connector
    var setRestoreStarted: () -> Void = {}
    var setRestoreFailed: (Error) -> Void = { _ in }
    var setRestoreCompleted: (CustomerInfo) -> Void = { _ in }
    var setShowingManageSubscriptions: () -> Void = {}
    var setRefundRequestStarted: (String) -> Void = { _ in }
    var setRefundRequestCompleted: (RefundRequestStatus) -> Void = { _ in }
    var setFeedbackSurveyCompleted: (String) -> Void = { _ in }

    init(customerCenterActionHandler: CustomerCenterActionHandler?) {
        self.customerCenterActionHandler = customerCenterActionHandler
    }

    func handleAction(_ action: CustomerCenterAction) {
        // Note: The deprecated handler should be called by the view model,
        // so we're not calling it here to avoid duplication

        // Directly invoke the appropriate setter based on the action
        switch action {
        case .restoreStarted:
            setRestoreStarted()
        case .restoreFailed(let error):
            setRestoreFailed(error)
        case .restoreCompleted(let customerInfo):
            setRestoreCompleted(customerInfo)
        case .showingManageSubscriptions:
            setShowingManageSubscriptions()
        case .refundRequestStarted(let productId):
            setRefundRequestStarted(productId)
        case .refundRequestCompleted(let status):
            setRefundRequestCompleted(status)
        case .feedbackSurveyCompleted(let optionId):
            setFeedbackSurveyCompleted(optionId)
        }
    }

    /// Handles the action by calling both the deprecated handler and setting the preference
    /// This is a convenience method for transitioning code to use the new system
    func handleActionWithDeprecatedHandler(_ action: CustomerCenterAction) {
        // Call the deprecated handler
        customerCenterActionHandler?(action)

        // Set the preference
        handleAction(action)
    }
}
