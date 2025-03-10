//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterActionWrapper.swift
//  
//  Created by Cesar de la Vega on 2024-06-17.

import RevenueCat
import SwiftUI

/// Internal enum that represents all possible actions in the Customer Center
/// This includes both actions that exist in the public CustomerCenterAction enum
/// and new internal-only actions (like buttonTapped)
internal enum CustomerCenterInternalAction {

    // Actions that map directly to public CustomerCenterAction cases
    case restoreStarted
    case restoreFailed(Error)
    case restoreCompleted(CustomerInfo)
    case showingManageSubscriptions
    case refundRequestStarted(String)
    case refundRequestCompleted(RefundRequestStatus)
    case feedbackSurveyCompleted(String)

    // New internal-only actions that don't exist in the public legacy CustomerCenterAction
    case buttonTapped(buttonId: String)

    /// Converts this internal action to the corresponding public action if one exists
    /// Returns nil for actions that don't have a public CustomerCenterAction equivalent
    var asPublicAction: CustomerCenterAction? {
        switch self {
        case .restoreStarted:
            return .restoreStarted
        case .restoreFailed(let error):
            return .restoreFailed(error)
        case .restoreCompleted(let customerInfo):
            return .restoreCompleted(customerInfo)
        case .showingManageSubscriptions:
            return .showingManageSubscriptions
        case .refundRequestStarted(let productId):
            return .refundRequestStarted(productId)
        case .refundRequestCompleted(let status):
            return .refundRequestCompleted(status)
        case .feedbackSurveyCompleted(let optionId):
            return .feedbackSurveyCompleted(optionId)
        case .buttonTapped:
            return nil // No public equivalent
        }
    }
}

/// Helper class that wraps actions for the Customer Center with a unified API
/// It handles both legacy CustomerCenterAction and new internal action types
@MainActor
final class CustomerCenterActionWrapper {

    // Direct setter closures that will be set by the preference connector
    var setRestoreStarted: () -> Void = {}
    var setRestoreFailed: (Error) -> Void = { _ in }
    var setRestoreCompleted: (CustomerInfo) -> Void = { _ in }
    var setShowingManageSubscriptions: () -> Void = {}
    var setRefundRequestStarted: (String) -> Void = { _ in }
    var setRefundRequestCompleted: (RefundRequestStatus) -> Void = { _ in }
    var setFeedbackSurveyCompleted: (String) -> Void = { _ in }
    var setButtonTapped: (String) -> Void = { _ in }

    // The handler for legacy actions
    private let legacyActionHandler: DeprecatedCustomerCenterActionHandler?

    init(legacyActionHandler: DeprecatedCustomerCenterActionHandler?) {
        self.legacyActionHandler = legacyActionHandler
    }

    /// Main entry point for handling all actions
    /// For legacy CustomerCenterAction, calls the legacy handler and triggers callbacks
    /// For non-legacy actions, only triggers callbacks
    func handleAction(_ action: CustomerCenterInternalAction) {
        // For actions with a legacy equivalent, call the legacy handler
        if let legacyAction = action.asPublicAction {
            legacyActionHandler?(legacyAction)
        }

        // Trigger callbacks for all actions
        triggerCallbacks(for: action)
    }

    private func triggerCallbacks(for action: CustomerCenterInternalAction) {
        switch action {
        case .restoreStarted:
            #if DEBUG
            print("DEBUG: 🚀 Triggering RestoreStarted action")
            #endif
            setRestoreStarted()
        case .restoreFailed(let error):
            #if DEBUG
            print("DEBUG: ❌ Triggering RestoreFailed action with error: \(error.localizedDescription)")
            #endif
            setRestoreFailed(error)
        case .restoreCompleted(let customerInfo):
            #if DEBUG
            print("DEBUG: ✅ Triggering RestoreCompleted action for user: \(customerInfo.originalAppUserId)")
            #endif
            setRestoreCompleted(customerInfo)
        case .showingManageSubscriptions:
            #if DEBUG
            print("DEBUG: 📱 Triggering ShowingManageSubscriptions action")
            #endif
            setShowingManageSubscriptions()
        case .refundRequestStarted(let productId):
            #if DEBUG
            print("DEBUG: 💰 Triggering RefundRequestStarted action for product: \(productId)")
            #endif
            setRefundRequestStarted(productId)
        case .refundRequestCompleted(let status):
            #if DEBUG
            print("DEBUG: 📋 Triggering RefundRequestCompleted action with status: \(status)")
            #endif
            setRefundRequestCompleted(status)
        case .feedbackSurveyCompleted(let optionId):
            #if DEBUG
            print("DEBUG: 📊 Triggering FeedbackSurveyCompleted action with option: \(optionId)")
            #endif
            setFeedbackSurveyCompleted(optionId)
        case .buttonTapped(let buttonId):
            #if DEBUG
            print("DEBUG: 👆 Triggering ButtonTapped action for button: \(buttonId)")
            #endif
            setButtonTapped(buttonId)
        }
    }
}
