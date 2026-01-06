//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentView.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView: View {

    @Environment(\.openURL)
    private var openURL

    @Environment(\.purchaseInitiatedAction)
    private var purchaseInitiatedAction: PurchaseInitiatedAction?

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    @State private var inAppBrowserURL: URL?

    private let viewModel: PurchaseButtonComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: PurchaseButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    /// Show activity indicator only if purchase action in purchase handler
    var showActivityIndicatorOverContent: Bool {
        guard let actionType = self.purchaseHandler.actionTypeInProgress else {
            return false
        }

        switch actionType {
        case .purchase, .pendingPurchaseContinuation:
            return true
        case .restore:
            return false
        }
    }

    /// Disable for any type of purchase handler action
    var shouldBeDisabled: Bool {
        return self.purchaseHandler.actionInProgress
    }

    var body: some View {
        AsyncButton {
            try await self.purchase()
        } label: {
            // Not passing an onDismiss - nothing in this stack should be able to dismiss
            StackComponentView(
                viewModel: viewModel.stackViewModel,
                onDismiss: {},
                showActivityIndicatorOverContent: self.showActivityIndicatorOverContent
            )
        }
        .applyIf(self.shouldBeDisabled) {
            $0.disabled(true)
                .opacity(0.35)
        }
        #if canImport(SafariServices) && canImport(UIKit)
        .sheet(isPresented: .isNotNil(self.$inAppBrowserURL)) {
            SafariView(url: self.inAppBrowserURL!)
        }
        #endif
    }

    private func purchase() async throws {
        guard let method = self.viewModel.method else {
            try await self.purchaseInApp()
            return
        }

        switch method {
        case .inAppCheckout, .unknown:
            try await self.purchaseInApp()
        case .webCheckout, .webProductSelection, .customWebCheckout:
            try await self.purchaseInWeb()
        }
    }

    private func purchaseInApp() async throws {
        self.logIfInPreview(package: self.packageContext.package)

        guard !self.purchaseHandler.actionInProgress else {
            return
        }

        guard let selectedPackage = self.packageContext.package else {
            Logger.error(Strings.no_selected_package_found)
            return
        }

        // Check if there's a purchase interceptor
        if let interceptor = self.purchaseInitiatedAction {
            let result = await self.purchaseHandler.withPendingPurchaseContinuation {
                await withCheckedContinuation { continuation in
                    interceptor(selectedPackage, resume: ResumeAction { shouldProceed in
                        continuation.resume(returning: shouldProceed)
                    })
                }
            }
            guard result else { return }
        }

        let promoOffer = self.paywallPromoOfferCache.get(for: selectedPackage)

        _ = try await self.purchaseHandler.purchase(package: selectedPackage, promotionalOffer: promoOffer)
    }

    private func purchaseInWeb() async throws {
        self.logIfInPreview(package: self.packageContext.package)

        guard let launchWebCheckout = self.viewModel.urlForWebCheckout(packageContext: packageContext) else {
            Logger.error(Strings.no_web_checkout_url_found)
            return
        }

        self.logIfInPreview("Web Product: \(launchWebCheckout)")

        guard !self.isInPreview else {
            return
        }

        self.openWebPaywallLink(launchWebCheckout: launchWebCheckout)
    }

    private func openWebPaywallLink(launchWebCheckout: PurchaseButtonComponentViewModel.LaunchWebCheckout) {
        Purchases.shared.invalidateCustomerInfoCache()

        let method = launchWebCheckout.method
        let url = launchWebCheckout.url

        Browser.navigateTo(url: url,
                           method: method,
                           openURL: self.openURL,
                           inAppBrowserURL: self.$inAppBrowserURL)

        if launchWebCheckout.autoDismiss {
            self.onDismiss()
        }
    }

    private var isInPreview: Bool {
        #if DEBUG
        let isInPreview: Bool = ProcessInfo.isRunningForPreviews

        return isInPreview
        #else
        return false
        #endif
    }

    /// Used to see purchasing information when using SwiftUI Previews
    private func logIfInPreview(package: Package?) {
        #if DEBUG
        guard let package else { return }

        self.logIfInPreview(
            "Purchasing package: \(package.identifier)"
        )
        #endif
    }

    private func logIfInPreview(_ value: String) {
        #if DEBUG
        if self.isInPreview {
            print(value)
        }
        #endif
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView_Previews: PreviewProvider {

    static var previews: some View {
        // Pill
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    stack: .init(components: [
                        // WIP: Intro offer state with "id_2",
                        .text(.init(
                            text: "id_1",
                            fontWeight: .bold,
                            color: .init(light: .hex("#ffffff")),
                            backgroundColor: .init(light: .hex("#ff0000")),
                            padding: .init(top: 10,
                                           bottom: 10,
                                           leading: 30,
                                           trailing: 30)
                        ))
                    ]),
                    action: .inAppCheckout,
                    method: .inAppCheckout
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("Hello, world intro offer")
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
            onDismiss: {
            }
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Pill")

        // Rounded Rectangle
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    stack: .init(
                        components: [
                            // WIP: Intro offer state with "id_2",
                            .text(.init(
                                text: "id_1",
                                fontWeight: .bold,
                                color: .init(light: .hex("#ffffff"))
                            ))
                        ],
                        backgroundColor: .init(light: .hex("#ff0000")),
                        padding: .init(top: 8,
                                       bottom: 8,
                                       leading: 8,
                                       trailing: 8),
                        shape: .rectangle(.init(topLeading: 8,
                                                topTrailing: 8,
                                                bottomLeading: 8,
                                                bottomTrailing: 8))
                    ),
                    action: .inAppCheckout,
                    method: .inAppCheckout
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("Hello, world intro offer")
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
            onDismiss: {
            }
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Rounded Rectangle")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension PurchaseButtonComponentViewModel {

    convenience init(
        component: PaywallComponent.PurchaseButtonComponent,
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
            localizationProvider: localizationProvider,
            component: component,
            offering: offering,
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
