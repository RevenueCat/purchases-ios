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

import Combine
@_spi(Internal) import RevenueCat
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
    case showingChangePlans(String?)
    case refundRequestStarted(String)
    case refundRequestCompleted(String, RefundRequestStatus)
    case feedbackSurveyCompleted(String)

    // New internal-only actions that don't exist in the public legacy CustomerCenterAction
    case buttonTapped(action: CustomerCenterActionable)
    // Internal action for when a promotional offer succeeds
    case promotionalOfferSuccess
    case customActionSelected(CustomActionData)

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
        case .buttonTapped,
                .promotionalOfferSuccess,
                .showingChangePlans,
                .customActionSelected:
            return nil // No public equivalent
        }
    }
}

/// Helper class that wraps actions for the Customer Center with a unified API
/// It handles both legacy CustomerCenterAction and new internal action types
@MainActor
final class CustomerCenterActionWrapper {

    private let legacyActionHandler: DeprecatedCustomerCenterActionHandler?

    // Combine publishers for each action
    let restoreStarted = PassthroughSubject<Void, Never>()
    let restoreFailed = PassthroughSubject<NSError, Never>()
    let restoreCompleted = PassthroughSubject<CustomerInfo, Never>()
    let showingManageSubscriptions = PassthroughSubject<Void, Never>()
    let showingChangePlans = PassthroughSubject<String?, Never>()
    let refundRequestStarted = PassthroughSubject<String, Never>()
    let refundRequestCompleted = PassthroughSubject<(String, RefundRequestStatus), Never>()
    let feedbackSurveyCompleted = PassthroughSubject<String, Never>()
    let managementOptionSelected = PassthroughSubject<CustomerCenterActionable, Never>()
    let customActionSelected = PassthroughSubject<(String, String?), Never>()
    let promotionalOfferSuccess = PassthroughSubject<Void, Never>()

    init(legacyActionHandler: DeprecatedCustomerCenterActionHandler? = nil) {
        self.legacyActionHandler = legacyActionHandler
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handleAction(_ action: CustomerCenterInternalAction) {
        if let legacyAction = action.asLegacyAction {
            legacyActionHandler?(legacyAction)
        }

        switch action {
        case .restoreStarted:
            restoreStarted.send(())

        case .restoreFailed(let error):
            restoreFailed.send(error as NSError)

        case .restoreCompleted(let info):
            restoreCompleted.send(info)

        case .showingManageSubscriptions:
            showingManageSubscriptions.send(())

        case .refundRequestStarted(let productId):
            refundRequestStarted.send(productId)

        case .refundRequestCompleted(let productId, let status):
            refundRequestCompleted.send((productId, status))

        case .feedbackSurveyCompleted(let reason):
            feedbackSurveyCompleted.send(reason)

        case .buttonTapped(let action):
            managementOptionSelected.send(action)

        case .customActionSelected(let customActionData):
            customActionSelected.send((customActionData.actionIdentifier, customActionData.purchaseIdentifier))

        case .promotionalOfferSuccess:
            promotionalOfferSuccess.send(())

        case .showingChangePlans(let subscriptionGroupID):
            showingChangePlans.send(subscriptionGroupID)
        }
    }
}

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterActionWrapper {

    var restoreStartedPublisher: AnyPublisher<Void, Never> { restoreStarted.eraseToAnyPublisher() }
    var restoreFailedPublisher: AnyPublisher<NSError, Never> { restoreFailed.eraseToAnyPublisher() }
    var restoreCompletedPublisher: AnyPublisher<CustomerInfo, Never> { restoreCompleted.eraseToAnyPublisher() }
    var showingManageSubscriptionsPublisher: AnyPublisher<Void, Never> {
        showingManageSubscriptions.eraseToAnyPublisher()
    }
    var showingChangePlansPublisher: AnyPublisher<String?, Never> { showingChangePlans.eraseToAnyPublisher() }
    var refundRequestStartedPublisher: AnyPublisher<String, Never> { refundRequestStarted.eraseToAnyPublisher() }
    var refundRequestCompletedPublisher: AnyPublisher<(String, RefundRequestStatus), Never> {
        refundRequestCompleted.eraseToAnyPublisher()
    }
    var feedbackSurveyCompletedPublisher: AnyPublisher<String, Never> { feedbackSurveyCompleted.eraseToAnyPublisher() }
    var managementOptionSelectedPublisher: AnyPublisher<CustomerCenterActionable, Never> {
        managementOptionSelected.eraseToAnyPublisher()
    }
    var customActionSelectedPublisher: AnyPublisher<(String, String?), Never> {
        customActionSelected.eraseToAnyPublisher()
    }
    var promotionalOfferSuccessPublisher: AnyPublisher<Void, Never> {
        promotionalOfferSuccess.eraseToAnyPublisher()
    }
}

#endif

// MARK: - Help Path to Management Option Conversion
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterConfigData.HelpPath {

    /// Converts this HelpPath to an appropriate CustomerCenterActionable
    /// - Parameter purchaseIdentifier: The optional active purchase ID for the context
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
