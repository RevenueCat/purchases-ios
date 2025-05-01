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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView: View {
    @Environment(\.openURL) private var openURL
    @State private var inAppBrowserURL: URL?
    @State private var showCustomerCenter = false
    @State private var showingWebPaywallLinkAlert = false
    @State private var webPaywallLinkURL: URL?

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: ButtonComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    /// Show activity indicator only if restore action in purchase handler
    var showActivityIndicatorOverContent: Bool {
        guard self.viewModel.isRestoreAction,
                let actionType = self.purchaseHandler.actionTypeInProgress else {
            return false
        }

        switch actionType {
        case .purchase:
            return false
        case .restore:
            return true
        }
    }

    /// Disable for any type of purchase handler action
    var shouldBeDisabled: Bool {
        return self.viewModel.isRestoreAction && self.purchaseHandler.actionInProgress
    }

    var body: some View {
        if !self.viewModel.hasUnknownAction {
            AsyncButton {
                try await performAction()
            } label: {
                StackComponentView(
                    viewModel: self.viewModel.stackViewModel,
                    onDismiss: self.onDismiss,
                    showActivityIndicatorOverContent: self.showActivityIndicatorOverContent
                )
            }
            .alert("Open in web browser?",
                   isPresented: $showingWebPaywallLinkAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open") {
                    if let url = webPaywallLinkURL {
#if os(watchOS)
                        // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
                        openURL(url)
#else
                        openURL(url) { success in
                            if success {
                                Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                            } else {
                                Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                            }
                        }
#endif
                        onDismiss()
                    }
                }
            } message: {
                Text("You will leave the app and go to the developer’s website.")
            }
            .applyIf(self.shouldBeDisabled, apply: { view in
                view
                    .disabled(true)
                    .opacity(0.35)
            })
            #if canImport(SafariServices) && canImport(UIKit)
            .sheet(isPresented: .isNotNil(self.$inAppBrowserURL)) {
                SafariView(url: self.inAppBrowserURL!)
            }
            #if os(iOS)
            .presentCustomerCenter(isPresented: self.$showCustomerCenter, onDismiss: {
                self.showCustomerCenter = false
            })
            #endif
            #endif
        }
    }

    private func performAction() async throws {
        switch viewModel.action {
        case .restorePurchases:
            try await restorePurchases()
        case .navigateTo(let destination):
            navigateTo(destination: destination)
        case .navigateBack:
            onDismiss()
        case .unknown:
            break
        }
    }

    private func restorePurchases() async throws {
        guard !self.purchaseHandler.actionInProgress else { return }

        Logger.debug(Strings.restoring_purchases)

        let (customerInfo, success) = try await self.purchaseHandler.restorePurchases()
        if success {
            Logger.debug(Strings.restored_purchases)
            self.purchaseHandler.setRestored(customerInfo)
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
        case .unknown:
            break
        case .webPaywallLink(url: let url, method: let method):
            openWebPaywallLink(url: url, method: method)
        }
    }

    private func navigateToUrl(url: URL, method: PaywallComponent.ButtonComponent.URLMethod) {
        switch method {
        case .inAppBrowser:
#if os(tvOS)
            // There's no SafariServices on tvOS, so we're falling back to opening in an external browser.
            Logger.warning(Strings.no_in_app_browser_tvos)
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                } else {
                    Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                }
            }
#else
            inAppBrowserURL = url
#endif
        case .externalBrowser:
#if os(watchOS)
            // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
            openURL(url)
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                } else {
                    Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                }
            }
#endif
        case .deepLink:
#if os(watchOS)
            // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
            openURL(url)
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_deep_link(url.absoluteString))
                } else {
                    Logger.error(Strings.failed_to_open_url_deep_link(url.absoluteString))
                }
            }
#endif
        case .unknown:
            break
        }
    }

    private func openWebPaywallLink(url: URL, method: PaywallComponent.ButtonComponent.URLMethod) {
        var url = url.appendingPathComponent(Purchases.shared.appUserID)
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            var items = components.queryItems ?? []
            items.append(.init(name: "rc_source", value: "app"))
            components.queryItems = items
            url = components.url ?? url
        }
        Purchases.shared.invalidateCustomerInfoCache()
        webPaywallLinkURL = url
        showingWebPaywallLinkAlert = true
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
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "buttonText": PaywallComponentsData.LocalizationData.string("Do something")
                        ]
                    ),
                    offering: Offering(identifier: "", serverDescription: "", availablePackages: [])
                ),
                onDismiss: { }
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension ButtonComponentViewModel {

    convenience init(
        component: PaywallComponent.ButtonComponent,
        localizationProvider: LocalizationProvider,
        offering: Offering
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            firstImageInfo: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            offering: offering
        )

        try self.init(
            component: component,
            localizationProvider: localizationProvider,
            offering: offering,
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
