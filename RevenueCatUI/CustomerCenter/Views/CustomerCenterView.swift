//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

/// Use the Customer Center in your app to help your customers manage common support tasks.
///
/// Customer Center is a self-service UI that can be added to your app to help
/// your customers manage their subscriptions on their own. With it, you can prevent
/// churn with pre-emptive promotional offers, capture actionable customer data with
/// exit feedback prompts, and lower support volumes for common inquiries — all
/// without any help from your support team.
///
/// The `CustomerCenterView` can be used to integrate the Customer Center directly in your app with SwiftUI.
///
/// For more information, see the [Customer Center docs](https://www.revenuecat.com/docs/tools/customer-center).
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CustomerCenterView: View {

    @StateObject private var viewModel: CustomerCenterViewModel
    @State private var ignoreAppUpdateWarning: Bool = false

    @Environment(\.colorScheme)
    private var colorScheme

    private let mode: CustomerCenterPresentationMode

    /// Create a view to handle common customer support tasks
    /// - Parameters:
    ///   - customerCenterActionHandler: An optional `CustomerCenterActionHandler` to handle actions
    ///   from the Customer Center.
    public init(customerCenterActionHandler: CustomerCenterActionHandler? = nil) {
        self.init(customerCenterActionHandler: customerCenterActionHandler, mode: .default)
    }

    /// Create a view to handle common customer support tasks
    /// - Parameters:
    ///   - customerCenterActionHandler: An optional `CustomerCenterActionHandler` to handle actions
    ///   from the Customer Center.
    init(customerCenterActionHandler: CustomerCenterActionHandler? = nil,
         mode: CustomerCenterPresentationMode) {
        self._viewModel = .init(wrappedValue:
                                    CustomerCenterViewModel(customerCenterActionHandler: customerCenterActionHandler))
        self.mode = mode
    }

    fileprivate init(viewModel: CustomerCenterViewModel,
                     mode: CustomerCenterPresentationMode = CustomerCenterPresentationMode.default) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.mode = mode
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        Group {
            switch self.viewModel.state {
            case .error:
                ErrorView()
            case .notLoaded:
                TintedProgressView()
            case .success:
                if let configuration = self.viewModel.configuration {
                    destinationView(configuration: configuration)
                        .environment(\.localization, configuration.localization)
                        .environment(\.appearance, configuration.appearance)
                        .environment(\.supportInformation, configuration.support)
                        .environment(\.customerCenterPresentationMode, self.mode)
                } else {
                    TintedProgressView()
                }
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
        .task {
#if DEBUG
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
#endif
            self.trackImpression()
        }
        .environmentObject(self.viewModel)
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterView {

    func loadInformationIfNeeded() async {
        if viewModel.state == .notLoaded {
            await viewModel.loadScreen()
        }
    }

    @ViewBuilder
    func destinationContent(configuration: CustomerCenterConfigData) -> some View {
        if let purchaseInformation = viewModel.purchaseInformation {
            if purchaseInformation.store == .appStore,
               let screen = configuration.screens[.management] {
                if let onUpdateAppClick = viewModel.onUpdateAppClick,
                    !ignoreAppUpdateWarning && viewModel.shouldShowAppUpdateWarnings {
                    AppUpdateWarningView(
                        onUpdateAppClick: onUpdateAppClick,
                        onContinueAnywayClick: {
                            withAnimation {
                                ignoreAppUpdateWarning = true
                            }
                        }
                    )
                } else {
                    ManageSubscriptionsView(screen: screen,
                                            purchaseInformation: purchaseInformation,
                                            customerCenterActionHandler: viewModel.customerCenterActionHandler)
                }
            } else if let screen = configuration.screens[.management] {
                WrongPlatformView(screen: screen,
                                  purchaseInformation: purchaseInformation)
            } else {
                WrongPlatformView(purchaseInformation: purchaseInformation)
            }
        } else {
            if let screen = configuration.screens[.noActive] {
                ManageSubscriptionsView(screen: screen,
                                        purchaseInformation: nil,
                                        customerCenterActionHandler: viewModel.customerCenterActionHandler)
            } else {
                // Fallback with a restore button
                NoSubscriptionsView(configuration: configuration)
            }
        }
    }

    @ViewBuilder
    func destinationView(configuration: CustomerCenterConfigData) -> some View {
        let accentColor = Color.from(colorInformation: configuration.appearance.accentColor,
                                     for: self.colorScheme)

        CompatibilityNavigationStack {
            destinationContent(configuration: configuration)
        }
        .applyIf(accentColor != nil, apply: { $0.tint(accentColor) })
    }

    func trackImpression() {
        viewModel.trackImpression(darkMode: self.colorScheme == .dark,
                                  displayMode: self.mode)
    }

}

#if DEBUG

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterView_Previews: PreviewProvider {

    static var previews: some View {
        let purchaseInformationApple =
        CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing
        let viewModelApple = CustomerCenterViewModel(purchaseInformation: purchaseInformationApple,
                                                     configuration: CustomerCenterConfigTestData.customerCenterData)
        CustomerCenterView(viewModel: viewModelApple)
            .previewDisplayName("Monthly Apple")
    }

}

#endif

#endif
