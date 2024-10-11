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
#if canImport(SafariServices)
import SafariServices
#endif
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView: View {
    @Environment(\.openURL) var openURL
    @State private var inAppBrowserURL: URL?

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: ButtonComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        AsyncButton(
            action: { try await onClick() },
            label: { StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: self.onDismiss) }
        ).sheet(isPresented: .isNotNil($inAppBrowserURL)) {
            SafariView(url: inAppBrowserURL!)
        }
    }

    private func onClick() async throws {
        switch viewModel.component.action {
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

    private func navigateTo(destination: PaywallComponent.ButtonComponent.Destination) {
        switch destination {
        case .customerCenter:
            // swiftlint:disable:next todo
            // TODO handle navigating to customer center
            break
        case .URL(let urlLid, let method),
                .privacyPolicy(let urlLid, let method),
                .terms(let urlLid, let method):
            navigateToUrl(urlLid: urlLid, method: method)
        }
    }

    private func navigateToUrl(urlLid: String, method: PaywallComponent.ButtonComponent.URLMethod) {
        guard let urlString = try? viewModel.localizedStrings.string(key: urlLid),
        let url = URL(string: urlString) else {
            Logger.error(Strings.paywall_invalid_url(urlLid))
            return
        }

        switch method {
        case .inAppBrowser:
#if os(tvOS)
            // There's no SafariServices on tvOS, so we're falling back to opening in an external browser.
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

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: UIViewControllerRepresentableContext<SafariView>
    ) {
        // No updates needed
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
                                        textLid: "buttonText",
                                        color: .init(light: "#000000")
                                    )
                                )
                            ],
                            backgroundColor: nil
                        )
                    ),
                    locale: Locale(identifier: "en_US"),
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

#endif

#endif
