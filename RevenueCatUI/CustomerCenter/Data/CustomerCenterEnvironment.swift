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
/// Handlers for external host-app callbacks from the Customer Center UI.
///
/// This type is intended for external use only (host app callbacks). Internal UI logic
/// should subscribe to `CustomerCenterActionWrapper` publishers in ViewModels instead of
/// registering environment handlers to avoid overriding host handlers.
final class CustomerCenterExternalActions: @unchecked Sendable {
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
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum CustomerCenterExternalActionsKey: EnvironmentKey {
    static let defaultValue = CustomerCenterExternalActions()
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EnvironmentValues {
    var customerCenterExternalActions: CustomerCenterExternalActions {
        get { self[CustomerCenterExternalActionsKey.self] }
        set { self[CustomerCenterExternalActionsKey.self] = newValue }
    }
}

#endif
