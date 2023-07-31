//
//  SamplePaywalls.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

import Foundation
import RevenueCat

final class SamplePaywallLoader {

    private let packages: [Package]

    init(packages: [Package]) {
        self.packages = packages
    }

    static func create() async throws -> Self {
        struct PurchasesNotConfigured: Error {}

        guard Purchases.isConfigured else {
            throw PurchasesNotConfigured()
        }

        let packages = try await Purchases.shared.offerings().current?.availablePackages

        return .init(packages: packages ?? [])
    }

    func offering(for template: PaywallTemplate) -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: self.paywall(for: template),
            availablePackages: self.packages
        )
    }

    func offeringWithDefaultPaywall() -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: nil,
            availablePackages: self.packages
        )
    }

    private func paywall(for template: PaywallTemplate) -> PaywallData {
        switch template {
        case .onePackageStandard:
            return Self.onePackageStandardTemplate()
        case .multiPackageBold:
            return Self.multiPackageBoldTemplate()
        case .onePackageWithFeatures:
            return Self.onePackageWithFeaturesTemplate()
        }
    }

}

private extension SamplePaywallLoader {
    
    static func onePackageStandardTemplate() -> PaywallData {
        return .init(
            template: .onePackageStandard,
            config: .init(
                packages: [.monthly],
                images: Self.images,
                colors:  .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#000000",
                        callToActionBackground: "#5CD27A",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#BC66FF"
                    ),
                    dark: .init(
                        background: "#000000",
                        text1: "#FFFFFF",
                        callToActionBackground: "#ACD27A",
                        callToActionForeground: "#000000",
                        accent1: "#B022BB"
                    )
                ),
                termsOfServiceURL: Self.tosURL
            ),
            localization: .init(
                title: "Ignite your child's curiosity",
                subtitle: "Get access to all our educational content trusted by thousands of parents.",
                callToAction: "Purchase for {{ price }}",
                callToActionWithIntroOffer: "Purchase for {{ price_per_month }} per month",
                offerDetails: "{{ price_per_month }} per month",
                offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func multiPackageBoldTemplate() -> PaywallData {
        return .init(
            template: .multiPackageBold,
            config: .init(
                packages: [.weekly, .monthly, .annual],
                images: Self.images,
                colors:  .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#000000",
                        callToActionBackground: "#EC807C",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#BC66FF",
                        accent2: "#222222"
                    ),
                    dark: .init(
                        background: "#000000",
                        text1: "#FFFFFF",
                        callToActionBackground: "#ACD27A",
                        callToActionForeground: "#000000",
                        accent1: "#B022BB",
                        accent2: "#CCCCCC"
                    )
                ),
                blurredBackgroundImage: true,
                termsOfServiceURL: Self.tosURL
            ),
            localization: .init(
                title: "Call to action for better conversion.",
                subtitle: "Lorem ipsum is simply dummy text of the printing and typesetting industry.",
                callToAction: "Subscribe for {{ price_per_month }}/mo",
                offerDetails: "{{ total_price_and_per_month }}",
                offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ intro_duration }} trial",
                offerName: "{{ period }}"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func onePackageWithFeaturesTemplate() -> PaywallData {
        return .init(
            template: .onePackageWithFeatures,
            config: .init(
                packages: [.annual],
                images: Self.images,
                colors: .init(
                    light: .init(
                        background: "#272727",
                        text1: "#FFFFFF",
                        callToActionBackground: "#FFFFFF",
                        callToActionForeground: "#000000",
                        accent1: "#F4E971",
                        accent2: "#B7B7B7"
                    )
                ),
                termsOfServiceURL: Self.tosURL
            ),
            localization: .init(
                title: "How your free trial works",
                callToAction: "Start",
                callToActionWithIntroOffer: "Start your {{ intro_duration }} free",
                offerDetails: "Only {{ price }} per {{ period }}",
                offerDetailsWithIntroOffer: "First {{ intro_duration }} free, then\n{{ price }} per year ({{ price_per_month }} per month)",
                features: [
                    .init(title: "Today",
                          content: "Full access to 1000+ workouts plus free meal plan worth $49.99.",
                          iconID: "tick"),
                    .init(title: "Day 7",
                          content: "Get a reminder about when your trial is about to end.",
                          iconID: "notifications"),
                    .init(title: "Day 14",
                          content: "You'll automatically get subscribed. Cancel anytime before if you didn't love our app.",
                          iconID: "attachment")
                ]),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

}

private extension SamplePaywallLoader {

    static let images: PaywallData.Configuration.Images = .init(
        header: "9a17e0a7_1689854430..jpeg",
        background: "9a17e0a7_1689854342..jpg",
        icon: "9a17e0a7_1689854430..jpeg"
    )

    static let offeringIdentifier = "offering"
    static let paywallAssetBaseURL = URL(string: "https://d35rwhxn1vk1te.cloudfront.net")!
    static let tosURL = URL(string: "https://revenuecat.com/tos")!

}

// This is provided by RevenueCatUI only for debug builds
// But we want to be able to use it in release builds too.
#if !DEBUG

extension PaywallColor: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(stringRepresentation: value)
    }

}

#endif
