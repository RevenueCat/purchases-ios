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

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger

    @State private var inAppBrowserURL: URL?
    @State private var hostedCheckoutSession: HostedCheckoutSheetSession?

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

    /// Disable for an in-flight purchase/restore. Do not include the hosted
    /// checkout sheet — this view presents that sheet, and `.disabled` would
    /// make the sheet ignore taps.
    var shouldBeDisabled: Bool {
        return self.purchaseHandler.shouldDisablePaywallControls
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
        .disabled(self.shouldBeDisabled)
        .opacity(self.shouldBeDisabled ? 0.35 : 1.0)
        #if canImport(WebKit) && canImport(UIKit) && !os(tvOS)
        .sheet(isPresented: .isNotNil(self.$inAppBrowserURL)) {
            WebCheckoutView(url: self.inAppBrowserURL!)
        }
        .sheet(item: self.$hostedCheckoutSession, onDismiss: {
            self.purchaseHandler.endHostedCheckoutSheet()
        }) { session in
            WebCheckoutView(viewModel: session.viewModel) { result in
                Task { await self.handleHostedCheckoutFinished(result, session: session) }
            }
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
        case .webCheckout:
            try await self.purchaseInWeb(tryHostedStripe: true)
        case .webProductSelection, .customWebCheckout:
            try await self.purchaseInWeb(tryHostedStripe: false)
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

        self.logPurchaseButtonInteractionForInApp(selectedPackage: selectedPackage)

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

        let promoOffer = self.paywallPromoOfferCache.purchasableOffer(for: selectedPackage)

        _ = try await self.purchaseHandler.purchase(package: selectedPackage, promotionalOffer: promoOffer)
    }

    private func purchaseInWeb(tryHostedStripe: Bool) async throws {
        self.logIfInPreview(package: self.packageContext.package)

        guard let launchWebCheckout = self.viewModel.urlForWebCheckout(
            packageContext: self.packageContext,
            appUserID: Purchases.isConfigured ? Purchases.shared.appUserID : "",
            isSandbox: Purchases.isConfigured ? Purchases.shared.isSandbox : false
        ) else {
            Logger.error(Strings.no_web_checkout_url_found)
            return
        }

        self.logPurchaseButtonInteractionForWeb(launchWebCheckout: launchWebCheckout)

        self.logIfInPreview("Web Product: \(launchWebCheckout)")

        guard !self.isInPreview else {
            return
        }

        #if canImport(WebKit) && canImport(UIKit) && !os(tvOS)
        if tryHostedStripe, await self.openHostedStripeCheckoutIfAvailable() {
            return
        }
        #else
        _ = tryHostedStripe
        #endif
        self.openWebPaywallLink(launchWebCheckout: launchWebCheckout)
    }

    #if canImport(WebKit) && canImport(UIKit) && !os(tvOS)
    private func openHostedStripeCheckoutIfAvailable() async -> Bool {
        guard Purchases.isConfigured else {
            return false
        }

        guard !self.purchaseHandler.actionInProgress else {
            return true
        }

        guard let selectedPackage = self.packageContext.package else {
            return false
        }

        do {
            let session = try await self.purchaseHandler.withPurchaseAction {
                // Create the web view first so WebKit can start while we wait on the backend.
                let viewModel = WebCheckoutViewModel()
                let startResult = try await Purchases.shared.startHostedWebCheckout(
                    packageID: selectedPackage.identifier,
                    offeringIdentifier: selectedPackage.offeringIdentifier,
                    email: nil
                )
                viewModel.load(startResult.checkoutURL)
                await viewModel.waitUntilReady()
                return HostedCheckoutSheetSession(
                    operationSessionID: startResult.operationSessionID,
                    viewModel: viewModel
                )
            }

            self.purchaseHandler.beginHostedCheckoutSheet()
            self.hostedCheckoutSession = session
            self.purchaseHandler.signalWebCheckoutOpened()
            return true
        } catch {
            Logger.error(Strings.hosted_web_checkout_start_failed(error))
            return false
        }
    }

    private func handleHostedCheckoutFinished(
        _ result: WebCheckoutSheetResult,
        session: HostedCheckoutSheetSession
    ) async {
        guard result == .success, Purchases.isConfigured else {
            self.hostedCheckoutSession = nil
            self.purchaseHandler.endHostedCheckoutSheet()
            return
        }

        do {
            let customerInfo = try await Purchases.shared.finishHostedWebCheckout(
                operationSessionID: session.operationSessionID
            )
            await MainActor.run {
                self.purchaseHandler.completeHostedWebCheckout(customerInfo: customerInfo)
                self.purchaseHandler.endHostedCheckoutSheet()
                self.hostedCheckoutSession = nil
            }
        } catch {
            Logger.error(Strings.hosted_web_checkout_finish_failed(error))
            await MainActor.run {
                self.purchaseHandler.endHostedCheckoutSheet()
                self.hostedCheckoutSession = nil
            }
        }
    }
    #endif

    private func logPurchaseButtonInteractionForInApp(selectedPackage: Package) {
        let componentValue: String
        if let method = self.viewModel.method {
            componentValue = method.description
        } else {
            componentValue = PaywallComponent.PurchaseButtonComponent.Method.inAppCheckout.description
        }

        self.componentInteractionLogger(.paywallPurchaseButtonAction(
            componentName: self.viewModel.componentName,
            componentValue: componentValue,
            componentURL: nil,
            currentPackageIdentifier: selectedPackage.identifier,
            currentProductIdentifier: selectedPackage.storeProduct.productIdentifier
        ))
    }

    private func logPurchaseButtonInteractionForWeb(
        launchWebCheckout: PurchaseButtonComponentViewModel.LaunchWebCheckout
    ) {
        self.componentInteractionLogger(.paywallPurchaseButtonAction(
            componentName: self.viewModel.componentName,
            componentValue: self.viewModel.method?.description ?? "",
            componentURL: launchWebCheckout.url,
            currentPackageIdentifier: self.packageContext.package?.identifier,
            currentProductIdentifier: self.packageContext.package?.storeProduct.productIdentifier
        ))
    }

    private func openWebPaywallLink(launchWebCheckout: PurchaseButtonComponentViewModel.LaunchWebCheckout) {
        Purchases.shared.invalidateCustomerInfoCache()

        let method = launchWebCheckout.method
        let url = launchWebCheckout.url

        Browser.navigateTo(url: url,
                           method: method,
                           openURL: self.openURL,
                           inAppBrowserURL: self.$inAppBrowserURL)

        self.purchaseHandler.signalWebCheckoutOpened()

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

#if canImport(WebKit) && canImport(UIKit) && !os(tvOS)
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
private final class HostedCheckoutSheetSession: Identifiable {
    let id = UUID()
    let operationSessionID: String
    let viewModel: WebCheckoutViewModel

    init(operationSessionID: String, viewModel: WebCheckoutViewModel) {
        self.operationSessionID = operationSessionID
        self.viewModel = viewModel
    }
}
#endif

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
                    method: .inAppCheckout,
                    name: nil
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
                    method: .inAppCheckout,
                    name: nil
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
