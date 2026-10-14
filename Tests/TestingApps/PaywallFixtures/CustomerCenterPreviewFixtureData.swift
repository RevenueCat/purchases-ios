// Created by Monika on 2026-10-14.

import Foundation
@_spi(Internal) import RevenueCat

/// Small local paywalls for testing link interception and dismissal through Customer Center.
enum CustomerCenterPreviewFixtureData {
    static func offering() -> Offering {
        let package = PaywallFixture.iconOnlyButton.packages[0]
        let mode = ProcessInfo.processInfo.environment["PREVIEW_PAYWALL"] ?? "legacy"
        if mode == "legacy" {
            let paywall = PaywallData(
                templateName: "1",
                config: .init(packages: [package.identifier], images: .init(), colors: .init(light: .init()),
                              termsOfServiceURL: URL(string: "https://example.invalid/terms"),
                              privacyURL: URL(string: "https://example.invalid/privacy")),
                localization: .init(title: "Legacy preview", callToAction: "Preview purchase"),
                assetBaseURL: URL(string: "https://example.invalid")!
            )
            return Offering(identifier: "preview", serverDescription: "Preview", paywall: paywall,
                            availablePackages: [package], webCheckoutUrl: nil)
        }

        let stack = PaywallComponent.StackComponent(components: [
            .text(.init(text: "action", color: .init(light: .hex("#000000"))))
        ], size: .init(width: .fill, height: .fixed(56)), backgroundColor: .init(light: .hex("#eeeeee")))
        let action: PaywallComponent
        if mode == "web_link" {
            action = .button(.init(action: .navigateTo(destination: .webPaywallLink(urlLid: "url", method: .externalBrowser)),
                                   stack: stack))
        } else {
            action = .purchaseButton(.init(stack: stack, action: nil, method: .customWebCheckout(.init(
                customUrl: .init(url: "url", appUserIDParam: "user", envParam: "env"),
                autoDismiss: mode == "checkout_dismiss", openMethod: .inAppBrowser
            )), name: nil))
        }
        let data = PaywallComponentsData(
            templateName: "preview", assetBaseURL: URL(string: "https://example.invalid")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: [
                    .button(.init(action: .navigateBack, stack: .init(components: [
                        .text(.init(text: "close", color: .init(light: .hex("#000000"))))
                    ], size: .init(width: .fill, height: .fixed(48))))),
                    action
                ], size: .init(width: .fill, height: .fill), spacing: 24,
                   padding: .init(top: 80, bottom: 24, leading: 16, trailing: 16)), stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": ["action": .string("Preview checkout"), "close": .string("Close preview"),
                                               "url": .string("https://example.invalid/checkout")]],
            revision: 1, defaultLocaleIdentifier: "en_US"
        )
        let uiConfig = UIConfig(app: .init(colors: [:], fonts: [:]), localizations: [:],
                                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:]))
        return Offering(identifier: "preview", serverDescription: "Preview",
                        paywallComponents: .init(uiConfig: uiConfig, data: data),
                        availablePackages: [package], webCheckoutUrl: nil)
    }
}
