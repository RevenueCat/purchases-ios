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
    @Environment(\.openURL) private var openURL
    @State private var inAppBrowserURL: URL?

    private let viewModel: ButtonComponentViewModel

    internal init(viewModel: ButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(
            action: { performAction() },
            label: { StackComponentView(viewModel: viewModel.stackViewModel) }
        ).sheet(isPresented: .isNotNil($inAppBrowserURL)) {
            SafariView(url: inAppBrowserURL!)
        }
    }

    private func performAction() {
        switch viewModel.action {
        case .restorePurchases:
            // swiftlint:disable:next todo
            // TODO handle restoring purchases
            break
        case .navigateTo(let destination):
            navigateTo(destination: destination)
        case .navigateBack:
            // swiftlint:disable:next todo
            // TODO handle navigating back
            break
        }
    }

    private func navigateTo(destination: ButtonComponentViewModel.Destination) {
        switch destination {
        case .customerCenter:
            // swiftlint:disable:next todo
            // TODO handle navigating to customer center
            break
        case .URL(let url, let method),
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
                )
            )
        }
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }
}

#endif

#endif
