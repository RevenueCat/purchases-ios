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

/// Internal enum to represent both public CustomerCenterAction cases and internal-only actions
internal enum CustomerCenterInternalAction {
    case `public`(CustomerCenterAction)
    // Example of a new internal-only action that doesn't exist in the public API
    case buttonTapped(buttonId: String)
}

/// Helper class that bridges the CustomerCenterActionHandler to the new preference-based system
@MainActor
final class CustomerCenterActionBridge {

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
    func handleAction(_ internalAction: CustomerCenterInternalAction) {
        // For public legacy actions, call the legacy handler
        if case let .public(publicAction) = internalAction {
            legacyActionHandler?(publicAction)
        }

        // Trigger callbacks for all actions
        triggerCallbacks(for: internalAction)
    }

    private func triggerCallbacks(for action: CustomerCenterInternalAction) {
        switch action {
        case .public(let publicAction):
            switch publicAction {
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

        case .buttonTapped(let buttonId):
            setButtonTapped(buttonId)
        }
    }
}
