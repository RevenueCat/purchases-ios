//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEnvironment.swift
//
//  Created by Cesar de la Vega on 19/7/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

struct LocalizationKey: EnvironmentKey {

    static let defaultValue: CustomerCenterConfigData.Localization = .default

}

struct AppearanceKey: EnvironmentKey {

    static let defaultValue: CustomerCenterConfigData.Appearance = .default

}

struct SupportKey: EnvironmentKey {

    static let defaultValue: CustomerCenterConfigData.Support? = nil

}

struct CustomerCenterPresentationModeKey: EnvironmentKey {

    static let defaultValue: CustomerCenterPresentationMode = .default

}

extension CustomerCenterConfigData.Localization {

    /// Default ``CustomerCenterConfigData.Localization`` value for Environment usage
    public static let `default` = CustomerCenterConfigData.Localization(locale: "en_US", localizedStrings: [:])

}

extension CustomerCenterConfigData.Appearance {

    /// Default ``CustomerCenterConfigData.Appearance`` value for Environment usage
    public static let `default` = CustomerCenterConfigData.Appearance(
        accentColor: .init(),
        textColor: .init(),
        backgroundColor: .init(),
        buttonTextColor: .init(),
        buttonBackgroundColor: .init()
    )

}

struct CustomerCenterNavigationOptionsKey: EnvironmentKey {

    static let defaultValue: CustomerCenterNavigationOptions = .default
}

extension EnvironmentValues {

    var localization: CustomerCenterConfigData.Localization {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }

    var appearance: CustomerCenterConfigData.Appearance {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }

    var supportInformation: CustomerCenterConfigData.Support? {
        get { self[SupportKey.self] }
        set { self[SupportKey.self] = newValue }
    }

    var customerCenterPresentationMode: CustomerCenterPresentationMode {
        get { self[CustomerCenterPresentationModeKey.self] }
        set { self[CustomerCenterPresentationModeKey.self] = newValue }
    }

    var navigationOptions: CustomerCenterNavigationOptions {
        get { self[CustomerCenterNavigationOptionsKey.self] }
        set { self[CustomerCenterNavigationOptionsKey.self] = newValue }
    }

}

#if os(iOS)

// MARK: - Customer Center Actions Environment

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class CustomerCenterEnvironmentActions: @unchecked Sendable {
    // Composite closures invoked by the SDK
    var restoreStarted: @MainActor @Sendable () -> Void = {}
    var restoreFailed: @MainActor @Sendable (Error) -> Void = { _ in }
    var restoreCompleted: @MainActor @Sendable (CustomerInfo) -> Void = { _ in }
    var showingManageSubscriptions: @MainActor @Sendable () -> Void = {}
    var refundRequestStarted: @MainActor @Sendable (String) -> Void = { _ in }
    var refundRequestCompleted: @MainActor @Sendable (String, RefundRequestStatus) -> Void = { _, _ in }
    var feedbackSurveyCompleted: @MainActor @Sendable (String) -> Void = { _ in }
    var managementOptionSelected: @MainActor @Sendable (CustomerCenterActionable) -> Void = { _ in }
    var promotionalOfferSuccess: @MainActor @Sendable () -> Void = {}
    var changePlansSelected: @MainActor @Sendable (String) -> Void = { _ in }
    var customActionSelected: @MainActor @Sendable (String, String?) -> Void = { _, _ in }

    // Simple chaining helpers (no IDs)
    func addRestoreStarted(_ handler: @escaping @MainActor @Sendable () -> Void) {
        self.restoreStarted = handler
    }

    func addRestoreFailed(_ handler: @escaping @MainActor @Sendable (Error) -> Void) {
        self.restoreFailed = handler
    }

    func addRestoreCompleted(_ handler: @escaping @MainActor @Sendable (CustomerInfo) -> Void) {
        self.restoreCompleted = handler
    }

    func addShowingManageSubscriptions(_ handler: @escaping @MainActor @Sendable () -> Void) {
        self.showingManageSubscriptions = handler
    }

    func addRefundRequestStarted(_ handler: @escaping @MainActor @Sendable (String) -> Void) {
        self.refundRequestStarted = handler
    }

    func addRefundRequestCompleted(_ handler: @escaping @MainActor @Sendable (String, RefundRequestStatus) -> Void) {
        self.refundRequestCompleted = handler
    }

    func addFeedbackSurveyCompleted(_ handler: @escaping @MainActor @Sendable (String) -> Void) {
        self.feedbackSurveyCompleted = handler
    }

    func addManagementOptionSelected(_ handler: @escaping @MainActor @Sendable (CustomerCenterActionable) -> Void) {
        self.managementOptionSelected = handler
    }

    func addPromotionalOfferSuccess(_ handler: @escaping @MainActor @Sendable () -> Void) {
        self.promotionalOfferSuccess = handler
    }

    func addChangePlansSelected(_ handler: @escaping @MainActor @Sendable (String) -> Void) {
        self.changePlansSelected = handler
    }

    func addCustomActionSelected(_ handler: @escaping @MainActor @Sendable (String, String?) -> Void) {
        self.customActionSelected = handler
    }
}

// Conform environment actions to the internal action sink used by ViewModels
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterEnvironmentActions: CustomerCenterActionSink {
    func actionRestoreStarted() {
        self.restoreStarted()
    }

    func actionRestoreFailed(_ error: Error) {
        self.restoreFailed(error)
    }

    func actionRestoreCompleted(_ info: CustomerInfo) {
        self.restoreCompleted(info)
    }

    func actionShowingManageSubscriptions() {
        self.showingManageSubscriptions()
    }

    func actionRefundRequestStarted(_ productId: String) {
        self.refundRequestStarted(productId)
    }

    func actionRefundRequestCompleted(_ productId: String, _ status: RefundRequestStatus) {
        self.refundRequestCompleted(productId, status)
    }

    func actionFeedbackSurveyCompleted(_ reason: String) {
        self.feedbackSurveyCompleted(reason)
    }

    func actionManagementOptionSelected(_ action: CustomerCenterActionable) {
        self.managementOptionSelected(action)
    }

    func actionPromotionalOfferSuccess() {
        self.promotionalOfferSuccess()
    }

    func actionChangePlansSelected(_ subscriptionGroupID: String) {
        self.changePlansSelected(subscriptionGroupID)
    }

    func actionCustomActionSelected(_ actionIdentifier: String, _ activePurchaseId: String?) {
        self.customActionSelected(actionIdentifier, activePurchaseId)
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum CustomerCenterEnvironmentActionsKey: EnvironmentKey {
    static let defaultValue = CustomerCenterEnvironmentActions()
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EnvironmentValues {
    var customerCenterActions: CustomerCenterEnvironmentActions {
        get { self[CustomerCenterEnvironmentActionsKey.self] }
        set { self[CustomerCenterEnvironmentActionsKey.self] = newValue }
    }
}
#endif
