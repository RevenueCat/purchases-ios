//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentView.swift
//
//  Created by Jay Shortway on 02/10/2024.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView: View {
    @Environment(\.openURL) private var openURL
    @State private var inAppBrowserURL: URL?
    @State private var showCustomerCenter = false

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: ButtonComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        AsyncButton {
            try await performAction()
        } label: {
            StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: self.onDismiss)
        }
        #if canImport(SafariServices) && canImport(UIKit)
        .sheet(isPresented: .isNotNil($inAppBrowserURL)) {
            SafariView(url: inAppBrowserURL!)
        }.presentCustomerCenter(isPresented: $showCustomerCenter) {
            showCustomerCenter = false
        }
        #endif
    }

    private func performAction() async throws {
        switch viewModel.action {
        case .restorePurchases:
            try await restorePurchases()
        case .navigateTo(let destination):
            navigateTo(destination: destination)
        case .navigateBack:
            onDismiss()
        }
    }

    private func restorePurchases() async throws {
        guard !self.purchaseHandler.actionInProgress else { return }

        Logger.debug(Strings.restoring_purchases)

        let (_, success) = try await self.purchaseHandler.restorePurchases()
        if success {
            Logger.debug(Strings.restored_purchases)
        } else {
            Logger.debug(Strings.restore_purchases_with_empty_result)
        }
    }

    private func navigateTo(destination: ButtonComponentViewModel.Destination) {
        switch destination {
        case .customerCenter:
            showCustomerCenter = true
        case .url(let url, let method),
                .privacyPolicy(let url, let method),
                .terms(let url, let method):
            navigateToUrl(url: url, method: method)
        }
    }

    private func navigateToUrl(url: URL, method: PaywallComponent.ButtonComponent.URLMethod) {
        switch method {
        case .inAppBrowser:
#if os(tvOS)
            // There's no SafariServices on tvOS, so we're falling back to opening in an external browser.
            Logger.warning(Strings.no_in_app_browser_tvos)
            openURL(url)
#else
            inAppBrowserURL = url
#endif
        case .externalBrowser,
                .deepLink:
            openURL(url)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            ButtonComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        action: .navigateBack,
                        stack: .init(
                            components: [
                                PaywallComponent.text(
                                    PaywallComponent.TextComponent(
                                        text: "buttonText",
                                        color: .init(light: .hex("#000000"))
                                    )
                                )
                            ],
                            backgroundColor: nil
                        )
                    ),
                    localizedStrings: [
                        "buttonText": PaywallComponentsData.LocalizationData.string("Do something")
                    ],
                    offering: Offering(identifier: "", serverDescription: "", availablePackages: [])
                ),
                onDismiss: { }
            )
        }
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension ButtonComponentViewModel {

    convenience init(
        component: PaywallComponent.ButtonComponent,
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )

        try self.init(
            component: component,
            localizedStrings: localizedStrings,
            offering: offering,
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
