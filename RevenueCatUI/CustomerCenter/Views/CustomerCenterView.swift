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

/// Warning: This is currently in beta and subject to change.
///
/// A SwiftUI view for displaying a customer support common tasks
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
    ///   from the customer center.
    public init(customerCenterActionHandler: CustomerCenterActionHandler? = nil,
                mode: CustomerCenterPresentationMode = CustomerCenterPresentationMode.default) {
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
            if !self.viewModel.isLoaded {
                TintedProgressView()
            } else {
                if let configuration = self.viewModel.configuration {
                    destinationView(configuration: configuration)
                        .environment(\.localization, configuration.localization)
                        .environment(\.appearance, configuration.appearance)
                        .environment(\.supportInformation, configuration.support)
                }
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
        .task {
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
        if !viewModel.isLoaded {
            await viewModel.loadHasActivePurchases()
            await viewModel.loadCustomerCenterConfig()
        }
    }

    @ViewBuilder
    func destinationContent(configuration: CustomerCenterConfigData) -> some View {
        if viewModel.hasActiveProducts {
            if viewModel.hasAppleEntitlement,
               let screen = configuration.screens[.management] {
                if let productId = configuration.productId, !ignoreAppUpdateWarning && !viewModel.appIsLatestVersion {
                    AppUpdateWarningView(
                        productId: productId,
                        onContinueAnywayClick: {
                            withAnimation {
                                ignoreAppUpdateWarning = true
                            }
                        }
                    )
                } else {
                    ManageSubscriptionsView(screen: screen,
                                            customerCenterActionHandler: viewModel.customerCenterActionHandler)
                }
            } else {
                WrongPlatformView()
            }
        } else {
            NoSubscriptionsView(configuration: configuration)
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
       let viewModel = CustomerCenterViewModel(hasActiveProducts: false, hasAppleEntitlement: false)
       CustomerCenterView(viewModel: viewModel)
   }

}

#endif

#endif
