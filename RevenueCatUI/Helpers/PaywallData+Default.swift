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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallData {

    /// Default `PaywallData` to display when attempting to present a ``PaywallView`` with an offering
    /// that has no paywall configuration, or when that configuration is invalid.
    static func createDefault(
        with packages: [Package],
        locale: Locale
    ) -> Self {
        return self.createDefault(with: packages.map(\.identifier), locale: locale)
    }

    static func createDefault(
        with packageIdentifiers: [String],
        locale: Locale
    ) -> Self {
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
            localization: Self.localization(Localization.localizedBundle(locale)),
            assetBaseURL: Self.defaultTemplateBaseURL,
            revision: Self.revisionID,
            locale: locale
        )
    }

    static let defaultTemplate: PaywallTemplate = .template2

    static let appIconPlaceholder = "revenuecatui_default_paywall_app_icon"

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallData {

    static let colors: PaywallData.Configuration.ColorInformation = {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) else {
            return Self.fallbackColors
        }

        #if os(macOS) || os(watchOS)
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

    static func localization(_ localizedBundle: Bundle) -> PaywallData.LocalizedConfiguration {
        .init(
            title: "{{ app_name }}",
            subtitle: nil,
            callToAction: localizedBundle
                .localizedString(forKey: "Continue", value: nil, table: nil),
            offerDetails: "{{ total_price_and_per_month }}",
            offerDetailsWithIntroOffer: localizedBundle
                .localizedString(
                    forKey: "Default_offer_details_with_intro_offer",
                    value: "Start your {{ sub_offer_duration }} trial, then {{ total_price_and_per_month }}.",
                    table: nil
                )
        )
    }

    static let backgroundImage = "background.jpg"
    static let defaultTemplateBaseURL = Bundle.module.resourceURL ?? Bundle.module.bundleURL
    static let revisionID: Int = -1

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct DefaultPaywall_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: Self.offering) {
            #if os(watchOS)
            WatchTemplateView($0)
            #else
            Template2View($0)
            #endif
        }
    }

    static let offering = Offering(
        identifier: "offering",
        serverDescription: "Main offering",
        metadata: [:],
        paywall: .createDefault(
            with: [
                TestData.weeklyPackage,
                TestData.monthlyPackage,
                TestData.annualPackage
            ],
            locale: .current
        ),
        availablePackages: TestData.packages
    )

}

#endif

#endif
