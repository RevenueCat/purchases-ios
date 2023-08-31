//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallData+Default.swift
//
//  Created by Nacho Soto on 7/20/23.

import Foundation
import RevenueCat
import SwiftUI

#if canImport(SwiftUI)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PaywallData {

    /// Default `PaywallData` to display when attempting to present a ``PaywallView`` with an offering
    /// that has no paywall configuration, or when that configuration is invalid.
    static func createDefault(with packages: [Package]) -> Self {
        return self.createDefault(with: packages.map(\.identifier))
    }

    static func createDefault(with packageIdentifiers: [String]) -> Self {
        return .init(
            templateName: Self.defaultTemplate.rawValue,
            config: .init(
                packages: packageIdentifiers,
                images: .init(
                    background: Self.backgroundImage,
                    icon: Self.appIconPlaceholder
                ),
                colors: Self.colors,
                blurredBackgroundImage: true,
                displayRestorePurchases: true
            ),
            localization: Self.localization,
            assetBaseURL: Self.defaultTemplateBaseURL,
            revision: Self.revisionID
        )
    }

    static let defaultTemplate: PaywallTemplate = .template2

    static let appIconPlaceholder = "revenuecatui_default_paywall_app_icon"
    static let revisionID: Int = -1

}

private extension PaywallData {

    static let colors: PaywallData.Configuration.ColorInformation = {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) else {
            return Self.fallbackColors
        }

        #if os(macOS)
        return Self.fallbackColors
        #else
        let background: PaywallColor = .init(light: Color.white.asPaywallColor, dark: Color.black.asPaywallColor)

        return .init(
            light: .init(
                background: background,
                text1: Color.primary.asPaywallColor,
                callToActionBackground: Color.accentColor.asPaywallColor,
                callToActionForeground: background,
                accent1: Color.accentColor.asPaywallColor,
                accent2: Color.primary.asPaywallColor
            )
        )
        #endif
    }()

    private static let fallbackColors: PaywallData.Configuration.ColorInformation = {
        // Paywalls aren't available prior to iOS 13 anyway,
        // but `PaywallData` is.
        // swiftlint:disable:next force_try
        let defaultColor: PaywallColor = try! .init(stringRepresentation: "#FFFFFF")

        return .init(light: .init(
            background: defaultColor,
            text1: defaultColor,
            callToActionBackground: defaultColor,
            callToActionForeground: defaultColor
        ))
    }()

    static let localization: PaywallData.LocalizedConfiguration = .init(
        title: "{{ app_name }}",
        subtitle: nil,
        callToAction: "Continue",
        offerDetails: "{{ total_price_and_per_month }}",
        offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, then {{ total_price_and_per_month }}."
    )

    static let backgroundImage = "background.jpg"
    static let defaultTemplateBaseURL = Bundle.module.resourceURL ?? Bundle.module.bundleURL

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
struct DefaultPaywall_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: Self.offering) {
            Template2View($0)
        }
    }

    static let offering = Offering(
        identifier: "offering",
        serverDescription: "Main offering",
        metadata: [:],
        paywall: .createDefault(with: [
            TestData.weeklyPackage,
            TestData.monthlyPackage,
            TestData.annualPackage
        ]),
        availablePackages: TestData.packages
    )

}

#endif

#endif
