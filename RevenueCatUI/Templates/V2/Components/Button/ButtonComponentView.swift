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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.openSheet) private var openSheet
    @Environment(\.offerCodeRedemptionInitiatedAction)
    private var offerCodeRedemptionInitiatedAction: OfferCodeRedemptionInitiatedAction?
    @State private var inAppBrowserURL: URL?
    @State private var showCustomerCenter = false
    @State private var offerCodeRedemptionSheet = false
    @State private var showingWebPaywallLinkAlert = false

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: ButtonComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: ButtonComponentViewModel,
                  onDismiss: @escaping () -> Void) {
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
        case .restore, .pendingPurchaseContinuation:
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
            .withTransition(viewModel.component.transition)
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
        case .sheet(let sheet):
            if let sheetStackViewModel = self.viewModel.sheetStackViewModel {
                let sheetViewModel = SheetViewModel(
                    sheet: sheet,
                    sheetStackViewModel: sheetStackViewModel
                )
                openSheet(sheetViewModel)
            }
        }
    }

    private func restorePurchases() async throws {
        guard !self.purchaseHandler.actionInProgress else { return }

        Logger.debug(Strings.restoring_purchases)

        let (customerInfo, success) = try await self.purchaseHandler.restorePurchases()
        if success {
            Logger.debug(Strings.restored_purchases)
        } else {
            Logger.debug(Strings.restore_purchases_with_empty_result)
        }

        self.purchaseHandler.setRestored(customerInfo, success: success)
    }

    private func navigateTo(destination: ButtonComponentViewModel.Destination) {
        switch destination {
        case .customerCenter:
            self.showCustomerCenter = true
        case .offerCodeRedemptionSheet:
            Task {
                await self.openCodeRedemptionSheet()
            }
        case .url(let url, let method),
                .privacyPolicy(let url, let method),
                .terms(let url, let method):
            Browser.navigateTo(url: url,
                               method: method,
                               openURL: self.openURL,
                               inAppBrowserURL: self.$inAppBrowserURL)
        case .unknown:
            break
        case .webPaywallLink(url: let url, method: let method):
            self.openWebPaywallLink(url: url, method: method)
        }
    }

    private func openCodeRedemptionSheet() async {
        // Check if there's an offer code redemption interceptor
        if let interceptor = self.offerCodeRedemptionInitiatedAction {
            // Wait for the interceptor to call resume before proceeding
            let result = await self.purchaseHandler.withPendingPurchaseContinuation {
                await withCheckedContinuation { continuation in
                    interceptor(resume: ResumeAction { shouldProceed in
                        continuation.resume(returning: shouldProceed)
                    })
                }
            }
            guard result else { return }
        }

#if os(iOS) && !targetEnvironment(macCatalyst)
        // Call the method only if available
        Purchases.shared.presentCodeRedemptionSheet()
#else
        // Handle the case for unsupported platforms (e.g., watchOS, macOS)
        print("presentCodeRedemptionSheet is unavailable on this platform")
#endif
    }

    private func openWebPaywallLink(url: URL, method: PaywallComponent.ButtonComponent.URLMethod) {
        self.purchaseHandler.invalidateCustomerInfoCache()
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
                    offering: Offering(
                        identifier: "",
                        serverDescription: "",
                        availablePackages: [],
                        webCheckoutUrl: nil
                    ),
                    colorScheme: .light
                ),
                onDismiss: { }
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension ButtonComponentViewModel {

    convenience init(
        component: PaywallComponent.ButtonComponent,
        localizationProvider: LocalizationProvider,
        offering: Offering,
        colorScheme: ColorScheme
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            firstItemIgnoresSafeAreaInfo: nil,
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            offering: offering,
            colorScheme: colorScheme
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
