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

/// Helper class that bridges the CustomerCenterActionHandler to the new preference-based system
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CustomerCenterActionBridge {

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

    /// Handles the action by calling both the deprecated handler and setting the preference
    /// This is a convenience method for transitioning code to use the new system
    func handleActionWithDeprecatedHandler(_ action: CustomerCenterAction) {
        // Call the deprecated handler
        customerCenterActionHandler?(action)

        // Set the preference
        handleAction(action)
    }

    private func handleAction(_ action: CustomerCenterAction) {
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
}
