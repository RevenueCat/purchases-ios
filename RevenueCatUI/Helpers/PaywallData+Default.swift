//
//  PaywallData+Default.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import Foundation
import RevenueCat

#if canImport(SwiftUI) && swift(>=5.7)

extension PaywallData {

    /// Default `PaywallData` to display when attempting to present a ``PaywallView`` with an offering
    /// that has no paywall configuration, or when that configuration is invalid.
    public static let `default`: Self = .init(
        template: .multiPackageBold,
        config: .init(
            packages: [.weekly, .monthly, .annual],
            images: .init(background: Self.backgroundImage),
            colors: Self.colors,
            blurredBackgroundImage: true,
            displayRestorePurchases: true
        ),
        localization: Self.localization,
        assetBaseURL: Self.defaultTemplateBaseURL
    )

}

private extension PaywallData {

    // swiftlint:disable force_try
    static let colors: PaywallData.Configuration.ColorInformation = .init(
        light: .init(
            background: try! .init(stringRepresentation: "#FFFFFF"),
            text1: try! .init(stringRepresentation: "#000000"),
            callToActionBackground: try! .init(stringRepresentation: "#FF8181"),
            callToActionForeground: try! .init(stringRepresentation: "#FFFFFF"),
            accent1: try! .init(stringRepresentation: "#BC66FF"),
            accent2: try! .init(stringRepresentation: "#111111")
        ),
        dark: .init(
            background: try! .init(stringRepresentation: "#000000"),
            text1: try! .init(stringRepresentation: "#FFFFFF"),
            callToActionBackground: try! .init(stringRepresentation: "#ACD27A"),
            callToActionForeground: try! .init(stringRepresentation: "#000000"),
            accent1: try! .init(stringRepresentation: "#BC66FF"),
            accent2: try! .init(stringRepresentation: "#EEEEEE")
        )
    )
    // swiftlint:enable force_try

    static let localization: PaywallData.LocalizedConfiguration = .init(
        title: "{{ app_name }}",
        subtitle: "Unlock full access with these subscriptions:",
        callToAction: "Continue",
        offerDetails: "{{ total_price_and_per_month }}.",
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ total_price_and_per_month }}."
    )

    static let backgroundImage = "background.jpg"
    static let defaultTemplateBaseURL = Bundle.module.resourceURL ?? Bundle.module.bundleURL

}

#endif
