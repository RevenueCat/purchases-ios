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
    case refundRequestCompleted(String, RefundRequestStatus)
    case feedbackSurveyCompleted(String)

    // New internal-only actions that don't exist in the public legacy CustomerCenterAction
    case buttonTapped(action: CustomerCenterActionable)
    // Internal action for when a promotional offer succeeds
    case promotionalOfferSuccess

    /// Converts this internal action to the corresponding legacy action if one exists
    /// Returns nil for actions that don't have a legacy CustomerCenterAction equivalent
    var asLegacyAction: CustomerCenterAction? {
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
        case .refundRequestCompleted(_, let status):
            return .refundRequestCompleted(status)
        case .feedbackSurveyCompleted(let optionId):
            return .feedbackSurveyCompleted(optionId)
        case .buttonTapped, .promotionalOfferSuccess:
            return nil // No public equivalent
        }
    }
}

/// Helper class that wraps actions for the Customer Center with a unified API
/// It handles both legacy CustomerCenterAction and new internal action types
@MainActor
final class CustomerCenterActionWrapper {

    private let legacyActionHandler: DeprecatedCustomerCenterActionHandler?

    private var restoreStartedCallbacks: [() -> Void] = []
    private var restoreFailedCallbacks: [(NSError) -> Void] = []
    private var restoreCompletedCallbacks: [(CustomerInfo) -> Void] = []
    private var showingManageSubscriptionsCallbacks: [() -> Void] = []
    private var refundRequestStartedCallbacks: [(String) -> Void] = []
    private var refundRequestCompletedCallbacks: [(String, RefundRequestStatus) -> Void] = []
    private var feedbackSurveyCompletedCallbacks: [(String) -> Void] = []
    private var managementOptionSelectedCallbacks: [(CustomerCenterActionable) -> Void] = []
    private var promotionalOfferSuccessCallbacks: [() -> Void] = []

    init(legacyActionHandler: DeprecatedCustomerCenterActionHandler? = nil) {
        self.legacyActionHandler = legacyActionHandler
    }

    /// Registers a new callback for each supported action
    func onRestoreStarted(_ callback: @escaping () -> Void) {
        restoreStartedCallbacks.append(callback)
    }

    func onRestoreFailed(_ callback: @escaping (NSError) -> Void) {
        restoreFailedCallbacks.append(callback)
    }

    func onRestoreCompleted(_ callback: @escaping (CustomerInfo) -> Void) {
        restoreCompletedCallbacks.append(callback)
    }

    func onShowingManageSubscriptions(_ callback: @escaping () -> Void) {
        showingManageSubscriptionsCallbacks.append(callback)
    }

    func onRefundRequestStarted(_ callback: @escaping (String) -> Void) {
        refundRequestStartedCallbacks.append(callback)
    }

    func onRefundRequestCompleted(_ callback: @escaping (String, RefundRequestStatus) -> Void) {
        refundRequestCompletedCallbacks.append(callback)
    }

    func onFeedbackSurveyCompleted(_ callback: @escaping (String) -> Void) {
        feedbackSurveyCompletedCallbacks.append(callback)
    }

    func onManagementOptionSelected(_ callback: @escaping (CustomerCenterActionable) -> Void) {
        managementOptionSelectedCallbacks.append(callback)
    }

    func onPromotionalOfferSuccess(_ callback: @escaping () -> Void) {
        promotionalOfferSuccessCallbacks.append(callback)
    }

    /// Main entry point for handling all actions
    func handleAction(_ action: CustomerCenterInternalAction) {
        if let legacyAction = action.asLegacyAction {
            legacyActionHandler?(legacyAction)
        }

        triggerCallbacks(for: action)
    }

    private func triggerCallbacks(for action: CustomerCenterInternalAction) {
        switch action {
        case .restoreStarted:
            restoreStartedCallbacks.forEach { $0() }

        case .restoreFailed(let error):
            restoreFailedCallbacks.forEach { $0(error as NSError) }

        case .restoreCompleted(let info):
            restoreCompletedCallbacks.forEach { $0(info) }

        case .showingManageSubscriptions:
            showingManageSubscriptionsCallbacks.forEach { $0() }

        case .refundRequestStarted(let productId):
            refundRequestStartedCallbacks.forEach { $0(productId) }

        case .refundRequestCompleted(let productId, let status):
            refundRequestCompletedCallbacks.forEach { $0(productId, status) }

        case .feedbackSurveyCompleted(let reason):
            feedbackSurveyCompletedCallbacks.forEach { $0(reason) }

        case .buttonTapped(let action):
            managementOptionSelectedCallbacks.forEach { $0(action) }

        case .promotionalOfferSuccess:
            promotionalOfferSuccessCallbacks.forEach { $0() }
        }
    }
}

// MARK: - Help Path to Management Option Conversion
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterConfigData.HelpPath {

    /// Converts this HelpPath to an appropriate CustomerCenterActionable
    /// - Returns: A CustomerCenterActionable representing this path
    func asAction() -> CustomerCenterActionable? {
        switch self.type {
        case .missingPurchase:
            return CustomerCenterManagementOption.MissingPurchase()

        case .refundRequest:
            return CustomerCenterManagementOption.RefundRequest()

        case .changePlans:
            return CustomerCenterManagementOption.ChangePlans()

        case .cancel:
            return CustomerCenterManagementOption.Cancel()

        case .customUrl:
            if let url = self.url {
                return CustomerCenterManagementOption.CustomUrl(url: url)
            }

        default:
            break
        }
        return nil
    }

}
