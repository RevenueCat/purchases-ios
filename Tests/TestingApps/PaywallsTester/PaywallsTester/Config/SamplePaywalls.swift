//
//  SamplePaywalls.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/27/23.
//

import Foundation
@_spi(Internal) import RevenueCat

#if DEBUG
@testable import RevenueCatUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class SamplePaywallLoader {

    private let packages: [Package]

    init() {
        self.packages = [
            Self.weeklyPackage,
            Self.monthlyPackage,
            Self.threeMonthPackage,
            Self.sixMonthPackage,
            Self.annualPackage,
            Self.lifetimePackage
        ]
    }

    func offering(for template: PaywallTemplate) -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: self.paywall(for: template),
            availablePackages: self.packages,
            webCheckoutUrl: nil
        )
    }

    #if !os(tvOS) // For Paywalls V2
    func offering(with components: PaywallComponentsData) -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: components),
            availablePackages: self.packages,
            webCheckoutUrl: nil
        )
    }
    #endif

    func offeringWithDefaultPaywall() -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: nil,
            availablePackages: self.packages,
            webCheckoutUrl: nil
        )
    }

    func offeringWithUnrecognizedPaywall() -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: Self.unrecognizedTemplate(),
            availablePackages: self.packages,
            webCheckoutUrl: nil
        )
    }

    let customerInfo = TestData.customerInfo

    private func paywall(for template: PaywallTemplate) -> PaywallData {
        switch template {
        case .template1:
            return Self.template1()
        case .template2:
            return Self.template2()
        case .template3:
            return Self.template3()
        case .template4:
            return Self.template4()
        case .template5:
            return Self.template5()
        case .template7:
            return Self.template7()
        }
    }

}

// MARK: - Packages

private extension SamplePaywallLoader {

    static let weeklyPackage = TestData.weeklyPackage
    static let monthlyPackage = TestData.monthlyPackage
    static let sixMonthPackage = TestData.sixMonthPackage
    static let threeMonthPackage = TestData.threeMonthPackage
    static let annualPackage = TestData.annualPackage
    static let lifetimePackage = TestData.lifetimePackage
}

// MARK: - Paywalls

private extension SamplePaywallLoader {

    static func template1() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template1.rawValue,
            config: .init(
                packages: [Package.string(from: PackageType.monthly)!],
                images: Self.images,
                imagesLowRes: Self.imagesLowRes,
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
                callToActionWithIntroOffer: "Purchase for {{ sub_price_per_month }} per month",
                offerDetails: "{{ sub_price_per_month }} per month",
                offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, then {{ sub_price_per_month }} per month"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template2() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template2.rawValue,
            config: .init(
                packages: Array<PackageType>([.weekly, .monthly, .annual, .lifetime])
                    .map { Package.string(from: $0)! },
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
                callToAction: "Subscribe for {{ price_per_period }}",
                offerDetails: "{{ total_price_and_per_month }}",
                offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ sub_offer_duration }} trial",
                offerName: "{{ sub_period }}"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template3() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template3.rawValue,
            config: .init(
                packages: [Package.string(from: .annual)!],
                images: Self.images,
                colors: .init(
                    light: .init(
                        background: "#FAFAFA",
                        text1: "#000000",
                        text2: "#2A2A2A",
                        callToActionBackground: "#222222",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#F4E971",
                        accent2: "#121212",
                        closeButton: "#00FF00"
                    ),
                    dark: .init(
                        background: "#272727",
                        text1: "#FFFFFF",
                        text2: "#B7B7B7",
                        callToActionBackground: "#FFFFFF",
                        callToActionForeground: "#000000",
                        accent1: "#F4E971",
                        accent2: "#4A4A4A",
                        closeButton: "#00FF00"
                    )
                ),
                termsOfServiceURL: Self.tosURL
            ),
            localization: .init(
                title: "How your free trial works",
                callToAction: "Start",
                callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free",
                offerDetails: "Only {{ price_per_period }}",
                offerDetailsWithIntroOffer: "First {{ sub_offer_duration }} free, then\n{{ price }} per year ({{ sub_price_per_month }} per month)",
                features: [
                    .init(title: "Today",
                          content: "Full access to 1000+ workouts plus free meal plan worth $49.99.",
                          iconID: "tick"),
                    .init(title: "Day 7",
                          content: "Get a reminder about when your trial is about to end.",
                          iconID: "notification"),
                    .init(title: "Day 14",
                          content: "You'll automatically get subscribed. Cancel anytime before if you didn't love our app.",
                          iconID: "attachment")
                ]),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template4() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template4.rawValue,
            config: .init(
                packages: Array<PackageType>([.monthly, .annual, .lifetime])
                    .map { Package.string(from: $0)! },
                defaultPackage: Package.string(from: .sixMonth)!,
                images: .init(background: "300883_1690710097.jpg"),
                colors: .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#111111",
                        callToActionBackground: "#06357D",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#D4B5FC",
                        accent2: "#DFDFDF"
                    )
                ),
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: .init(
                title: "Get _unlimited_ access",
                callToAction: "Continue",
                offerDetails: "Cancel anytime",
                offerDetailsWithIntroOffer: "Includes {{ sub_offer_duration }} **free** trial",
                offerName: "{{ sub_duration_in_months }}"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template5() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template5.rawValue,
            config: .init(
                packages: [PackageType.annual.identifier,
                           PackageType.monthly.identifier],
                defaultPackage: PackageType.annual.identifier,
                images: .init(
                    header: "954459_1692992845.png"
                ),
                colors: .init(
                    light: .init(
                        background: "#ffffff",
                        text1: "#000000",
                        text2: "#adf5c5",
                        text3: "#b15d5d",
                        callToActionBackground: "#45c186",
                        callToActionForeground: "#ffffff",
                        accent1: "#b24010",
                        accent2: "#027424",
                        accent3: "#D1D1D1"
                    ),
                    dark: .init(
                        background: "#000000",
                        text1: "#ffffff",
                        text2: "#adf5c5",
                        text3: "#b15d5d",
                        callToActionBackground: "#41E194",
                        callToActionForeground: "#000000",
                        accent1: "#41E194",
                        accent2: "#DFDFDF",
                        accent3: "#D1D1D1"
                    )
                ),
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: .init(
                title: "Spice Up Your Kitchen - Go Pro for Exclusive Benefits!",
                callToAction: "Continue",
                callToActionWithIntroOffer: "Start your Free Trial",
                offerDetails: "{{ total_price_and_per_month }}",
                offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                offerName: "{{ sub_period }}",
                features: [
                    .init(title: "Unique gourmet recipes", iconID: "tick"),
                    .init(title: "Advanced nutritional recipes", iconID: "apple"),
                    .init(title: "Personalized support from our Chef", iconID: "warning"),
                    .init(title: "Unlimited receipt collections", iconID: "bookmark")
                ]
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template7() -> PaywallData {
        return .init(
            templateName: PaywallTemplate.template7.rawValue,
            config: .init(
                images: .init(),
                imagesByTier: [
                    "basic": .init(
                        header: "954459_1703109702.png"
                    ),
                    "standard": .init(
                        header: "954459_1692992845.png"
                    ),
                    "premium": .init(
                        header: "954459_1701267532.jpeg"
                    )
                ],
                colors: .init(
                    light: .init(
                        background: "#ffffff",
                        text1: "#000000",
                        text2: "#ffffff",
                        text3: "#30A0F8AA",
                        callToActionForeground: "#ffffff",
                        accent2: "#7676801F"
                    ),
                    dark: .init(
                        background: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        text1: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).asPaywallColor,
                        text2: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).asPaywallColor,
                        text3: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        callToActionForeground: #colorLiteral(red: 0.5315951397, green: 1, blue: 0.4162791786, alpha: 1).asPaywallColor,
                        accent2: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1).asPaywallColor
                    )
                ),
                colorsByTier: [
                    "basic": .init(
                        light: .init(
                            background: "#ffffff",
                            text1: "#000000",
                            text2: "#ffffff",
                            text3: "#30A0F8AA",
                            callToActionBackground: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).asPaywallColor,
                            callToActionForeground: "#ffffff",
                            accent1: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1).asPaywallColor,
                            accent2: "#7676801F",
                            accent3: #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1).asPaywallColor
                        )
                    ),
                    "standard": .init(
                        light: .init(
                            background: "#ffffff",
                            text1: "#000000",
                            text2: "#ffffff",
                            text3: "#30A0F8AA",
                            callToActionBackground: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).asPaywallColor,
                            callToActionForeground: "#ffffff",
                            accent1: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1).asPaywallColor,
                            accent2: "#7676801F",
                            accent3: #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1).asPaywallColor
                        )
                    ),
                    "premium": .init(
                        light: .init(
                            background: "#ffffff",
                            text1: "#000000",
                            text2: "#ffffff",
                            text3: "#30A0F8AA",
                            callToActionBackground: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).asPaywallColor,
                            callToActionForeground: "#ffffff",
                            accent1: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1).asPaywallColor,
                            accent2: "#7676801F",
                            accent3: #colorLiteral(red: 0.1294117719, green: 0.2156862766, blue: 0.06666667014, alpha: 1).asPaywallColor
                        )
                    )
                ],
                tiers: [
                    .init(
                        id: "basic",
                        packages: [
                            Self.sixMonthPackage.identifier,
                            Self.lifetimePackage.identifier
                        ],
                        defaultPackage: Self.sixMonthPackage.identifier
                    ),
                    .init(
                        id: "standard",
                        packages: [
                            Self.weeklyPackage.identifier,
                            Self.monthlyPackage.identifier
                        ],
                        defaultPackage: Self.weeklyPackage.identifier
                    ),
                    .init(
                        id: "premium",
                        packages: [
                            Self.threeMonthPackage.identifier,
                            Self.annualPackage.identifier
                        ],
                        defaultPackage: Self.annualPackage.identifier
                    )
                ],
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localizationByTier: [
                "basic": .init(
                    title: "Get started with our Basic plan",
                    callToAction: "{{ price_per_period }}",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
                    offerDetails: "{{ total_price_and_per_month }}",
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                    offerOverrides: [
                        TestData.sixMonthPackage.identifier: .init(
                            offerDetails: "OVERRIDE six month details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE six month Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Six Month",
                            offerBadge: "LEAST FAVORITE"
                        ),
                        TestData.lifetimePackage.identifier: .init(
                            offerDetails: "OVERRIDE life details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE lifetime Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Lifetime ",
                            offerBadge: "LIFETIME"
                        )
                    ],
                    features: [
                        .init(title: "Access to 10 cinematic LUTs", iconID: "tick"),
                        .init(title: "Standard fonts", iconID: "tick"),
                        .init(title: "2 templates", iconID: "tick")
                    ],
                    tierName: "Basic"
                ),
                "standard": .init(
                    title: "Get started with our Standard plan",
                    callToAction: "{{ price_per_period }}",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
                    offerDetails: "{{ total_price_and_per_month }}",
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                    offerOverrides: [
                        TestData.weeklyPackage.identifier: .init(
                            offerDetails: "OVERRIDE weekly details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE weekly Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Weekly",
                            offerBadge: "{{ sub_relative_discount }}"
                        ),
                        TestData.monthlyPackage.identifier: .init(
                            offerDetails: "OVERRIDE monthly details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE monthly Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Monthly",
                            offerBadge: "{{ sub_relative_discount }}"
                        )
                    ],
                    features: [
                        .init(title: "Access to 30 cinematic LUTs", iconID: "tick"),
                        .init(title: "Pro fonts and transition effects", iconID: "tick"),
                        .init(title: "10+ templates", iconID: "tick")
                    ],
                    tierName: "Standard"
                ),
                "premium": .init(
                    title: "Master the art of video editing",
                    callToAction: "{{ price_per_period }}",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
                    offerDetails: "{{ total_price_and_per_month }}",
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                    offerOverrides: [
                        TestData.threeMonthPackage.identifier: .init(
                            offerDetails: "OVERRIDE three month details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE three month Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Three Month",
                            offerBadge: "{{ sub_relative_discount }}"
                        ),
                        TestData.annualPackage.identifier: .init(
                            offerDetails: "OVERRIDE annual details {{ total_price_and_per_month }}",
                            offerDetailsWithIntroOffer: "OVERRIDE annual Free for {{ sub_offer_duration }}, then {{ total_price_and_per_month }}",
                            offerName: "OVERRIDE Annual",
                            offerBadge: "{{ sub_relative_discount }}"
                        )
                    ],
                    features: [
                        .init(title: "Access to all 150 of our cinematic LUTs", iconID: "tick"),
                        .init(title: "Custom design tools and transition effects", iconID: "tick"),
                        .init(title: "100+ exclusive templates", iconID: "tick")
                    ],
                    tierName: "Premium"
                )
            ],
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func unrecognizedTemplate() -> PaywallData {
        return .init(
            templateName: "unrecognized_template_name",
            config: .init(
                packages: [Package.string(from: PackageType.monthly)!],
                images: Self.images,
                colors:  .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#000000",
                        callToActionBackground: "#5CD27A",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#BC66FF"
                    )
                ),
                termsOfServiceURL: Self.tosURL
            ),
            localization: .init(
                title: "Ignite your child's curiosity",
                subtitle: "Get access to all our educational content trusted by thousands of parents.",
                callToAction: "Purchase for {{ price }}",
                callToActionWithIntroOffer: "Purchase for {{ sub_price_per_month }} per month",
                offerDetails: "{{ sub_price_per_month }} per month",
                offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, then {{ sub_price_per_month }} per month"
            ),
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

    static let imagesLowRes: PaywallData.Configuration.Images = .init(
        header: "954459_1692984654.jpg",
        background: "954459_1692984654.jpg",
        icon: "954459_1692984654.jpg"
    )

    static let offeringIdentifier = "offering"
    static let paywallAssetBaseURL = URL(string: "https://assets.pawwalls.com")!
    static let tosURL = URL(string: "https://revenuecat.com/tos")!

}

// MARK: - State-driven Paywalls demo: Tab selected-state


#if !os(tvOS) // For Paywalls V2

extension SamplePaywallLoader {

    /// The state key the Tabs component writes to and the sibling components read from.
    /// In production the editor emits an id-based key (e.g. `cmp:<tabId>`); the SDK only requires
    /// that it is an opaque string, so any stable string works for a hand-authored demo.
    private static let planStateKey = "selected_plan"

    static func tabStateComponentsData() -> PaywallComponentsData {
        return .init(
            templateName: "state-driven-tabs-demo",
            assetBaseURL: Self.paywallAssetBaseURL,
            componentsConfig: .init(base: .init(
                stack: Self.tabStateRootStack(),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: [
                "en_US": [
                    // Tab control labels
                    "tab_monthly_label": .string("Monthly"),
                    "tab_annual_label": .string("Annual"),
                    "tab_lifetime_label": .string("Lifetime"),
                    // Per-tab content (inside the tabs)
                    "tab_monthly_title": .string("Monthly plan"),
                    "tab_monthly_desc": .string("Billed every month. Cancel anytime."),
                    "tab_annual_title": .string("Annual plan"),
                    "tab_annual_desc": .string("Billed once a year. Our most popular option."),
                    "tab_lifetime_title": .string("Lifetime access"),
                    "tab_lifetime_desc": .string("One payment. Yours forever, no renewals."),
                    // Reactive headline (text + color + size + weight change per tab)
                    "headline_monthly": .string("Flexible, no commitment"),
                    "headline_annual": .string("Best value — save 33%"),
                    "headline_lifetime": .string("Pay once, own it forever"),
                    // Reactive price (text + color change per tab)
                    "price_monthly": .string("$9.99 / month"),
                    "price_annual": .string("$79.99 / year"),
                    "price_lifetime": .string("$199.99 one-time"),
                    // Reactive savings banner (hidden on monthly; text + colors per tab)
                    "savings_annual": .string("🎉 2 months free vs. paying monthly"),
                    "savings_lifetime": .string("⏰ Limited-time lifetime offer")
                ]
            ],
            revision: 1,
            defaultLocaleIdentifier: "en_US",
            // The declared default matches `defaultTabId` so the first render is consistent.
            stateDeclarations: [
                Self.planStateKey: .init(type: "string", defaultValue: .string("monthly"))
            ]
        )
    }

    // MARK: Root layout

    private static func tabStateRootStack() -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .tabs(Self.planTabs()),
                // Everything below reacts to the selected tab via `state_condition` overrides.
                .icon(Self.reactivePlanIcon()),
                .text(Self.reactiveHeadline()),
                .stack(Self.reactivePriceCard()),
                .text(Self.reactiveSavingsBanner())
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill),
            spacing: 16,
            backgroundColor: .init(light: .hex("#ffffff")),
            padding: .init(top: 80, bottom: 24, leading: 16, trailing: 16)
        )
    }

    // MARK: Tabs (the component that publishes state)

    private static func planTabs() -> PaywallComponent.TabsComponent {
        return .init(
            size: .init(width: .fill, height: .fit),
            control: .init(
                type: .buttons,
                stack: .init(
                    components: [
                        Self.tabControlButton(tabId: "monthly", labelLid: "tab_monthly_label"),
                        Self.tabControlButton(tabId: "annual", labelLid: "tab_annual_label"),
                        Self.tabControlButton(tabId: "lifetime", labelLid: "tab_lifetime_label")
                    ],
                    dimension: .horizontal(.center, .start),
                    size: .init(width: .fit, height: .fit),
                    backgroundColor: .init(light: .hex("#dedede")),
                    padding: .init(top: 3, bottom: 3, leading: 3, trailing: 3),
                    shape: .pill
                )
            ),
            tabs: [
                Self.tab(id: "monthly", titleLid: "tab_monthly_title", descLid: "tab_monthly_desc"),
                Self.tab(id: "annual", titleLid: "tab_annual_title", descLid: "tab_annual_desc"),
                Self.tab(id: "lifetime", titleLid: "tab_lifetime_title", descLid: "tab_lifetime_desc")
            ],
            defaultTabId: "monthly",
            // Publishes the selected tab id into the store on every selection.
            stateUpdates: [
                .set(key: Self.planStateKey, value: .payloadReference)
            ]
        )
    }

    private static func tabControlButton(
        tabId: String,
        labelLid: String
    ) -> PaywallComponent {
        return .tabControlButton(.init(
            tabId: tabId,
            stack: .init(
                components: [
                    .text(.init(
                        text: labelLid,
                        color: .init(light: .hex("#000000")),
                        size: .init(width: .fit, height: .fit),
                        overrides: [
                            .init(conditions: [.selected], properties: .init(color: .init(light: .hex("#ffffff"))))
                        ]
                    ))
                ],
                size: .init(width: .fit, height: .fit),
                padding: .init(top: 8, bottom: 8, leading: 18, trailing: 18),
                shape: .pill,
                overrides: [
                    .init(conditions: [.selected], properties: .init(backgroundColor: .init(light: .hex("#3d6787"))))
                ]
            )
        ))
    }

    /// Each tab holds multiple components: the control (switcher) plus a title and a description.
    private static func tab(id: String, titleLid: String, descLid: String) -> PaywallComponent.TabsComponent.Tab {
        return .init(id: id, stack: .init(
            components: [
                .tabControl(.init()),
                .text(.init(
                    text: titleLid,
                    fontWeight: .bold,
                    color: .init(light: .hex("#111827")),
                    size: .init(width: .fit, height: .fit),
                    margin: .init(top: 16, bottom: 0, leading: 0, trailing: 0),
                    fontSize: 20
                )),
                .text(.init(
                    text: descLid,
                    color: .init(light: .hex("#6b7280")),
                    size: .init(width: .fill, height: .fit),
                    margin: .init(top: 4, bottom: 0, leading: 0, trailing: 0),
                    fontSize: 14
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fit),
            spacing: 4
        ))
    }

    // MARK: Reacting siblings (outside the tabs)

    /// Headline whose text, color, size and weight all change with the selected tab.
    /// Base = the "monthly" look; `annual` / `lifetime` are applied via `state` overrides.
    private static func reactiveHeadline() -> PaywallComponent.TextComponent {
        return .init(
            text: "headline_monthly",
            fontWeight: .regular,
            color: .init(light: .hex("#6b7280")),
            size: .init(width: .fill, height: .fit),
            fontSize: 18,
            horizontalAlignment: .center,
            overrides: [
                .init(extendedConditions: Self.whenPlan("annual"), properties: .init(
                    text: "headline_annual",
                    fontWeight: .bold,
                    color: .init(light: .hex("#1b873f")),
                    fontSize: 22
                )),
                .init(extendedConditions: Self.whenPlan("lifetime"), properties: .init(
                    text: "headline_lifetime",
                    fontWeight: .bold,
                    color: .init(light: .hex("#7c3aed")),
                    fontSize: 22
                ))
            ]
        )
    }

    /// A price "card" whose background color, corner shape and border change with the selected tab,
    /// wrapping a price label whose text and color also change. Both the stack and the inner text
    /// re-resolve independently from the same state key.
    private static func reactivePriceCard() -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: "price_monthly",
                    fontWeight: .bold,
                    color: .init(light: .hex("#111827")),
                    size: .init(width: .fit, height: .fit),
                    fontSize: 24,
                    overrides: [
                        .init(extendedConditions: Self.whenPlan("annual"), properties: .init(
                            text: "price_annual",
                            color: .init(light: .hex("#1b873f"))
                        )),
                        .init(extendedConditions: Self.whenPlan("lifetime"), properties: .init(
                            text: "price_lifetime",
                            color: .init(light: .hex("#7c3aed"))
                        ))
                    ]
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fit),
            backgroundColor: .init(light: .hex("#f3f4f6")),
            padding: .init(top: 24, bottom: 24, leading: 16, trailing: 16),
            shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12)),
            overrides: [
                .init(extendedConditions: Self.whenPlan("annual"), properties: .init(
                    backgroundColor: .init(light: .hex("#e7f7ec")),
                    shape: .rectangle(.init(topLeading: 20, topTrailing: 20, bottomLeading: 20, bottomTrailing: 20)),
                    border: .init(color: .init(light: .hex("#1b873f")), width: 2)
                )),
                .init(extendedConditions: Self.whenPlan("lifetime"), properties: .init(
                    backgroundColor: .init(light: .hex("#f3e8ff")),
                    shape: .rectangle(.init(topLeading: 20, topTrailing: 20, bottomLeading: 20, bottomTrailing: 20)),
                    border: .init(color: .init(light: .hex("#7c3aed")), width: 2)
                ))
            ]
        )
    }

    /// Banner hidden on the default (monthly) tab and revealed — with different copy and colors —
    /// on the annual and lifetime tabs.
    private static func reactiveSavingsBanner() -> PaywallComponent.TextComponent {
        return .init(
            visible: false,
            text: "savings_annual", // placeholder; not shown while hidden
            fontWeight: .semibold,
            color: .init(light: .hex("#1b873f")),
            backgroundColor: .init(light: .hex("#e7f7ec")),
            size: .init(width: .fill, height: .fit),
            padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16),
            fontSize: 15,
            overrides: [
                .init(extendedConditions: Self.whenPlan("annual"), properties: .init(
                    visible: true,
                    text: "savings_annual",
                    color: .init(light: .hex("#1b873f")),
                    backgroundColor: .init(light: .hex("#e7f7ec"))
                )),
                .init(extendedConditions: Self.whenPlan("lifetime"), properties: .init(
                    visible: true,
                    text: "savings_lifetime",
                    color: .init(light: .hex("#c2410c")),
                    backgroundColor: .init(light: .hex("#ffedd5"))
                ))
            ]
        )
    }

    /// A plan badge icon whose tint and circular background change with the selected tab — proof
    /// that Icon components re-resolve from state too. Base = monthly (gray glyph, no background);
    /// annual / lifetime add a colored circle behind a white glyph.
    private static func reactivePlanIcon() -> PaywallComponent.IconComponent {
        return .init(
            baseUrl: "https://icons.pawwalls.com/icons",
            iconName: "pizza",
            formats: .init(svg: "pizza.svg", png: "pizza.png", heic: "pizza.heic", webp: "pizza.webp"),
            size: .init(width: .fixed(56), height: .fixed(56)),
            padding: .zero,
            margin: .zero,
            color: .init(light: .hex("#6b7280")),
            iconBackground: nil,
            overrides: [
                .init(extendedConditions: Self.whenPlan("annual"), properties: .init(
                    padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12),
                    color: .init(light: .hex("#ffffff")),
                    iconBackground: .init(color: .init(light: .hex("#1b873f")), shape: .circle)
                )),
                .init(extendedConditions: Self.whenPlan("lifetime"), properties: .init(
                    padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12),
                    color: .init(light: .hex("#ffffff")),
                    iconBackground: .init(color: .init(light: .hex("#7c3aed")), shape: .circle)
                ))
            ]
        )
    }

    /// Builds the dedicated internal `state` condition for a given plan value. The public `Condition`
    /// enum has no `.state` case, so overrides are constructed via the `extendedConditions:` initializer.
    private static func whenPlan(_ value: String) -> [PaywallComponent.ExtendedCondition] {
        return [.state(operator: .equals, name: Self.planStateKey, value: .string(value))]
    }

}

// MARK: - Bundled component paywalls (loaded from JSON in the app bundle)

extension SamplePaywallLoader {

    /// Paywalls authored as Paywalls V2 component JSON and embedded directly in the tester app
    /// (see `BundledComponentPaywallJSON`). They are shown in the live paywall list alongside the
    /// offerings fetched from the server. The JSON is embedded rather than bundled as a resource so
    /// the paywalls appear after a plain rebuild, without needing to re-run `tuist generate`.
    private static let bundledComponentPaywalls: [(identifier: String, json: String)] = [
        (identifier: "Dog Paywall (Bundled)", json: BundledComponentPaywallJSON.dog),
        (identifier: "Cat Paywall (Bundled)", json: BundledComponentPaywallJSON.cat)
    ]

    /// Builds an offering for every embedded component paywall JSON that decodes successfully,
    /// plus the programmatically-built WebView capability samples.
    func bundledComponentOfferings() -> [Offering] {
        let jsonOfferings = Self.bundledComponentPaywalls.compactMap { paywall in
            Self.componentsData(fromJSON: paywall.json).map {
                self.offering(identifier: paywall.identifier, with: $0)
            }
        }
        return jsonOfferings + self.webViewCapabilityOfferings()
    }

    private func offering(identifier: String, with components: PaywallComponentsData) -> Offering {
        return .init(
            identifier: identifier,
            serverDescription: identifier,
            metadata: [:],
            paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: components),
            availablePackages: self.packages,
            webCheckoutUrl: nil
        )
    }

    /// Decodes an embedded component paywall JSON (which contains only the `componentsConfig`)
    /// and wraps it in a full `PaywallComponentsData` so it can back an `Offering`.
    private static func componentsData(fromJSON json: String) -> PaywallComponentsData? {
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }

        // Mirrors how the SDK decodes paywall responses from the server.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let componentsConfig = try? decoder.decode(
            PaywallComponentsData.ComponentsConfig.self,
            from: jsonData
        ) else {
            return nil
        }

        return .init(
            templateName: "components",
            assetBaseURL: Self.paywallAssetBaseURL,
            componentsConfig: componentsConfig,
            componentsLocalizations: Self.bundledComponentLocalizations,
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

    /// Placeholder localizations for the `*_lid` references in the bundled JSON. The JSON ships
    /// without its localization table, so these stand in to let the paywalls render with real text.
    private static let bundledComponentLocalizations:
        [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary] = [
            "en_US": [
                "b11T5KqURa": .string("Monthly"),
                "3PUpQs2Ysa": .string("{{ total_price_and_per_month }}"),
                "Hjy1nCtkxJ": .string("Annual"),
                "tzMoZfGK7q": .string("{{ total_price_and_per_month }}"),
                "pAwLNYbZ2e": .string("Best Value"),
                "uZcnB1JkxA": .string("Continue"),
                "n1dzcYoLL1": .string("Restore purchases"),
                "9pHXVuJRXm": .string("Terms & Conditions"),
                "PXTOmY0Zc3": .string("Privacy Policy"),
                "92rZFECc4Z": .string("https://www.revenuecat.com/terms"),
                "VBPJOj-Wkx": .string("https://www.revenuecat.com/privacy")
            ]
        ]

    // MARK: - WebView capability samples

    /// A WebView capability test paywall: a title plus a single `web_view` component pointing at the
    /// matching sample page on https://alexrepty.github.io/capabilities, with `capabilities` declared.
    private struct WebViewSample {
        /// Offering identifier shown in the tester list.
        let offeringID: String
        /// The `web_view` component id. Must equal the `?cid=` query value so bridge messages validate.
        let cid: String
        /// Heading shown above the web view.
        let title: String
        /// Sample page file name under `/capabilities`.
        let page: String
        /// Declared capabilities (nil grants nothing extra and leaves network unrestricted).
        let capabilities: PaywallComponent.WebViewCapabilities?
    }

    private static let webViewSamples: [WebViewSample] = [
        .init(offeringID: "WebView: Network (open)", cid: "cap_network_open",
              title: "Network · open", page: "network.html",
              capabilities: nil),
        .init(offeringID: "WebView: Network (restricted)", cid: "cap_network_restricted",
              title: "Network · restricted to alexrepty.github.io", page: "network.html",
              capabilities: .init(networkAccess: .init(allowedDomains: ["alexrepty.github.io"]))),
        .init(offeringID: "WebView: Camera (granted)", cid: "cap_camera_granted",
              title: "Camera · granted", page: "camera.html",
              capabilities: .init(camera: true)),
        .init(offeringID: "WebView: Camera (denied)", cid: "cap_camera_denied",
              title: "Camera · denied", page: "camera.html",
              capabilities: .init(camera: false)),
        .init(offeringID: "WebView: Microphone (granted)", cid: "cap_mic_granted",
              title: "Microphone · granted", page: "microphone.html",
              capabilities: .init(microphone: true)),
        .init(offeringID: "WebView: Microphone (denied)", cid: "cap_mic_denied",
              title: "Microphone · denied", page: "microphone.html",
              capabilities: .init(microphone: false)),
        .init(offeringID: "WebView: Clipboard (granted)", cid: "cap_clipboard_granted",
              title: "Clipboard · granted", page: "clipboard.html",
              capabilities: .init(clipboardWrite: true, clipboardRead: true)),
        .init(offeringID: "WebView: Clipboard (denied)", cid: "cap_clipboard_denied",
              title: "Clipboard · denied", page: "clipboard.html",
              capabilities: .init(clipboardWrite: false, clipboardRead: false)),
        .init(offeringID: "WebView: Geolocation (granted)", cid: "cap_geo_granted",
              title: "Geolocation · granted", page: "geolocation.html",
              capabilities: .init(geolocation: true)),
        .init(offeringID: "WebView: Geolocation (denied)", cid: "cap_geo_denied",
              title: "Geolocation · denied", page: "geolocation.html",
              capabilities: .init(geolocation: false)),
        .init(offeringID: "WebView: JS Bridge", cid: "cap_bridge",
              title: "JS bridge", page: "bridge.html",
              capabilities: nil)
    ]

    private static let webViewSampleBaseURL = "https://alexrepty.github.io/capabilities"

    /// Builds one offering per `WebViewSample`, each a minimal V2 paywall wrapping a `web_view`.
    func webViewCapabilityOfferings() -> [Offering] {
        return Self.webViewSamples.map { self.offering(for: $0) }
    }

    private func offering(for sample: WebViewSample) -> Offering {
        let titleLid = "title"
        let url = "\(Self.webViewSampleBaseURL)/\(sample.page)?cid=\(sample.cid)"

        let stack = PaywallComponent.StackComponent(
            components: [
                .text(.init(
                    text: titleLid,
                    fontWeight: .bold,
                    color: .init(light: .hex("#000000")),
                    size: .init(width: .fill, height: .fit),
                    fontSize: 18,
                    horizontalAlignment: .center
                )),
                .webView(.init(
                    id: sample.cid,
                    url: url,
                    size: .init(width: .fill, height: .fill),
                    capabilities: sample.capabilities
                ))
            ],
            dimension: .vertical(.center, .start),
            size: .init(width: .fill, height: .fill),
            spacing: 12,
            backgroundColor: .init(light: .hex("#ffffff")),
            padding: .init(top: 60, bottom: 24, leading: 16, trailing: 16)
        )

        let data = PaywallComponentsData(
            templateName: "components",
            assetBaseURL: Self.paywallAssetBaseURL,
            componentsConfig: .init(base: .init(
                stack: stack,
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": [titleLid: .string(sample.title)]],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        return self.offering(identifier: sample.offeringID, with: data)
    }

}

#endif

#endif

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


// MARK: - Embedded component paywall JSON

#if DEBUG && !os(tvOS)

/// Raw Paywalls V2 component JSON (the `componentsConfig` only) embedded in the tester app.
/// Embedded as source — rather than bundled as a resource — so the paywalls show up after a
/// plain rebuild without re-running `tuist generate`. See `SamplePaywallLoader`.
enum BundledComponentPaywallJSON {

    static let dog = #"""
{
  "base": {
    "background": {
      "type": "color",
      "value": {
        "light": {
          "type": "hex",
          "value": "#ffffffff"
        }
      }
    },
    "header": null,
    "stack": {
      "background": null,
      "background_color": null,
      "border": null,
      "components": [
        {
          "background": null,
          "background_color": null,
          "border": null,
          "components": [
            {
              "color_overlay": {
                "light": {
                  "degrees": 180,
                  "points": [
                    {
                      "color": "#ffffff00",
                      "percent": 72
                    },
                    {
                      "color": "#ffffffff",
                      "percent": 92
                    }
                  ],
                  "type": "linear"
                }
              },
              "fit_mode": "fit",
              "id": "C3L5jrSyft",
              "mask_shape": {
                "corners": null,
                "type": "rectangle"
              },
              "name": "",
              "size": {
                "height": {
                  "type": "fit",
                  "value": null
                },
                "width": {
                  "type": "fill",
                  "value": null
                }
              },
              "source": {
                "light": {
                  "heic": "https://assets.pawwalls.com/1181742_1734515710.heic",
                  "heic_low_res": "https://assets.pawwalls.com/1181742_low_res_1734515710.heic",
                  "height": 1306,
                  "original": "https://assets.pawwalls.com/1181742_1734515710.jpg",
                  "webp": "https://assets.pawwalls.com/1181742_1734515710.webp",
                  "webp_low_res": "https://assets.pawwalls.com/1181742_low_res_1734515710.webp",
                  "width": 1959
                }
              },
              "type": "image"
            },
            {
              "action": {
                "type": "navigate_back"
              },
              "id": "bu0_nTLC8M",
              "name": "Close button",
              "stack": {
                "background": null,
                "background_color": null,
                "border": null,
                "components": [
                  {
                    "base_url": "https://icons.pawwalls.com/icons",
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "formats": {
                      "heic": "x.heic",
                      "png": "x.png",
                      "svg": "x.svg",
                      "webp": "x.webp"
                    },
                    "icon_background": {
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#ffffffff"
                        }
                      },
                      "shape": {
                        "corners": null,
                        "type": "circle"
                      }
                    },
                    "icon_name": "x",
                    "id": "g6deqj_jtH",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 2,
                      "leading": 2,
                      "top": 2,
                      "trailing": 2
                    },
                    "size": {
                      "height": {
                        "type": "fixed",
                        "value": 24
                      },
                      "width": {
                        "type": "fixed",
                        "value": 24
                      }
                    },
                    "type": "icon"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "space_between",
                  "type": "vertical"
                },
                "id": "8fu3zVJgDj",
                "margin": {
                  "bottom": 0,
                  "leading": 0,
                  "top": 16,
                  "trailing": 16
                },
                "name": "",
                "padding": {
                  "bottom": 4,
                  "leading": 4,
                  "top": 4,
                  "trailing": 4
                },
                "shadow": null,
                "shape": {
                  "corners": {
                    "bottom_leading": 0,
                    "bottom_trailing": 0,
                    "top_leading": 0,
                    "top_trailing": 0
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fit",
                    "value": null
                  }
                },
                "spacing": 0,
                "type": "stack"
              },
              "type": "button"
            }
          ],
          "dimension": {
            "alignment": "top_trailing",
            "distribution": "space_between",
            "type": "zlayer"
          },
          "id": "1G0XaOjb8n",
          "margin": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "name": "Header stack",
          "padding": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "shadow": null,
          "shape": {
            "corners": {
              "bottom_leading": 0,
              "bottom_trailing": 0,
              "top_leading": 0,
              "top_trailing": 0
            },
            "type": "rectangle"
          },
          "size": {
            "height": {
              "type": "fit",
              "value": null
            },
            "width": {
              "type": "fill",
              "value": null
            }
          },
          "spacing": 0,
          "type": "stack"
        },
        {
  "id": "test_web_view_dog",
  "type": "web_view",
  "protocol_version": 1,
  "url": "https://alexrepty.github.io/dog.html",
  "size": {
    "width": { "type": "fixed", "value": 320 },
    "height": { "type": "fixed", "value": 240 }
  },
  "fallback": {
    "id": "test_web_view_dog_fallback",
    "type": "stack",
    "components": [],
    "size": { "width": { "type": "fixed", "value": 320 }, "height": { "type": "fixed", "value": 240 } },
    "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
    "margin":  { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
  }        },
        {
          "background": null,
          "background_color": null,
          "border": null,
          "components": [
            {
              "id": "f_ZGIReeHL",
              "is_selected_by_default": false,
              "name": "",
              "package_id": "$rc_monthly",
              "stack": {
                "background": null,
                "background_color": null,
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#d3d3d3ff"
                    }
                  },
                  "width": 1
                },
                "components": [
                  {
                    "background": null,
                    "background_color": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000ff"
                          }
                        },
                        "font_name": null,
                        "font_size": 16,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "id": "c13Mv5wrJU",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fill",
                            "value": null
                          }
                        },
                        "text_lid": "b11T5KqURa",
                        "type": "text"
                      },
                      {
                        "base_url": "https://icons.pawwalls.com/icons",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ccccccff"
                          }
                        },
                        "formats": {
                          "heic": "circle.heic",
                          "png": "circle.png",
                          "svg": "circle.svg",
                          "webp": "circle.webp"
                        },
                        "icon_background": null,
                        "icon_name": "circle",
                        "id": "SUpKRjECLa",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "overrides": [
                          {
                            "conditions": [
                              {
                                "type": "selected"
                              }
                            ],
                            "properties": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#4fcba6ff"
                                }
                              },
                              "formats": {
                                "heic": "circle-check.heic",
                                "png": "circle-check.png",
                                "svg": "circle-check.svg",
                                "webp": "circle-check.webp"
                              },
                              "icon_name": "circle-check"
                            }
                          }
                        ],
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fixed",
                            "value": 32
                          },
                          "width": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "type": "icon"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "space_between",
                      "type": "horizontal"
                    },
                    "id": "DhKZ9-WD_q",
                    "margin": {
                      "bottom": 16,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 8,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "rectangle"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "spacing": 12,
                    "type": "stack"
                  },
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "font_name": null,
                    "font_size": 16,
                    "font_weight": "bold",
                    "horizontal_alignment": "leading",
                    "id": "ahQAs554G5",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "text_lid": "3PUpQs2Ysa",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "start",
                  "type": "vertical"
                },
                "id": "ZHiZi-vIYb",
                "margin": {
                  "bottom": 4,
                  "leading": 8,
                  "top": 4,
                  "trailing": 8
                },
                "name": "",
                "overrides": [
                  {
                    "conditions": [
                      {
                        "type": "selected"
                      }
                    ],
                    "properties": {
                      "border": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba6ff"
                          }
                        },
                        "width": 1
                      },
                      "shadow": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba640"
                          }
                        },
                        "radius": 3,
                        "x": 1,
                        "y": 2
                      }
                    }
                  }
                ],
                "padding": {
                  "bottom": 8,
                  "leading": 16,
                  "top": 8,
                  "trailing": 16
                },
                "shadow": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#0505050d"
                    }
                  },
                  "radius": 3,
                  "x": 1,
                  "y": 2
                },
                "shape": {
                  "corners": {
                    "bottom_leading": 8,
                    "bottom_trailing": 8,
                    "top_leading": 8,
                    "top_trailing": 8
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fill",
                    "value": null
                  }
                },
                "spacing": 4,
                "type": "stack"
              },
              "type": "package"
            },
            {
              "id": "SNV2eGXTt5",
              "is_selected_by_default": true,
              "name": "",
              "package_id": "$rc_annual",
              "stack": {
                "background": null,
                "background_color": null,
                "badge": {
                  "alignment": "top",
                  "stack": {
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "type": "hex",
                          "value": "#9ef8ddff"
                        }
                      }
                    },
                    "background_color": {
                      "light": {
                        "type": "hex",
                        "value": "#9ef8ddff"
                      }
                    },
                    "badge": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000"
                          }
                        },
                        "font_name": null,
                        "font_size": 12,
                        "font_weight": "bold",
                        "horizontal_alignment": "center",
                        "id": "0x4zA6YxaH",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fit",
                            "value": null
                          }
                        },
                        "text_lid": "pAwLNYbZ2e",
                        "type": "text"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "center",
                      "type": "vertical"
                    },
                    "id": "gjSHZJt1ey",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 4,
                      "leading": 12,
                      "top": 4,
                      "trailing": 12
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 0,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "pill"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fit",
                        "value": null
                      }
                    },
                    "spacing": 0,
                    "type": "stack"
                  },
                  "style": "overlay"
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#d3d3d3ff"
                    }
                  },
                  "width": 1
                },
                "components": [
                  {
                    "background": null,
                    "background_color": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000"
                          }
                        },
                        "font_name": null,
                        "font_size": 16,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "id": "qCRoPQZknN",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fill",
                            "value": null
                          }
                        },
                        "text_lid": "Hjy1nCtkxJ",
                        "type": "text"
                      },
                      {
                        "base_url": "https://icons.pawwalls.com/icons",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ccccccff"
                          }
                        },
                        "formats": {
                          "heic": "circle.heic",
                          "png": "circle.png",
                          "svg": "circle.svg",
                          "webp": "circle.webp"
                        },
                        "icon_background": null,
                        "icon_name": "circle",
                        "id": "whelaBUPN5",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "overrides": [
                          {
                            "conditions": [
                              {
                                "type": "selected"
                              }
                            ],
                            "properties": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#4fcba6ff"
                                }
                              },
                              "formats": {
                                "heic": "circle-check.heic",
                                "png": "circle-check.png",
                                "svg": "circle-check.svg",
                                "webp": "circle-check.webp"
                              },
                              "icon_name": "circle-check"
                            }
                          }
                        ],
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fixed",
                            "value": 32
                          },
                          "width": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "type": "icon"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "space_between",
                      "type": "horizontal"
                    },
                    "id": "and6vK3XtL",
                    "margin": {
                      "bottom": 16,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 8,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "rectangle"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "spacing": 12,
                    "type": "stack"
                  },
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "font_name": null,
                    "font_size": 16,
                    "font_weight": "bold",
                    "horizontal_alignment": "leading",
                    "id": "hRGprKdmFd",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "text_lid": "tzMoZfGK7q",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "start",
                  "type": "vertical"
                },
                "id": "6esRiiY6GO",
                "margin": {
                  "bottom": 4,
                  "leading": 8,
                  "top": 4,
                  "trailing": 8
                },
                "name": "",
                "overrides": [
                  {
                    "conditions": [
                      {
                        "type": "selected"
                      }
                    ],
                    "properties": {
                      "border": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba6ff"
                          }
                        },
                        "width": 1
                      },
                      "shadow": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba640"
                          }
                        },
                        "radius": 12,
                        "x": 1,
                        "y": 4
                      }
                    }
                  }
                ],
                "padding": {
                  "bottom": 8,
                  "leading": 16,
                  "top": 8,
                  "trailing": 16
                },
                "shadow": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#0202020d"
                    }
                  },
                  "radius": 3,
                  "x": 0,
                  "y": 2
                },
                "shape": {
                  "corners": {
                    "bottom_leading": 8,
                    "bottom_trailing": 8,
                    "top_leading": 8,
                    "top_trailing": 8
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fill",
                    "value": null
                  }
                },
                "spacing": 4,
                "type": "stack"
              },
              "type": "package"
            }
          ],
          "dimension": {
            "alignment": "center",
            "distribution": "space_between",
            "type": "horizontal"
          },
          "id": "JivD_4KEjF",
          "margin": {
            "bottom": 0,
            "leading": 8,
            "top": 0,
            "trailing": 8
          },
          "name": "Package stack",
          "padding": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "shadow": null,
          "shape": {
            "corners": {
              "bottom_leading": 0,
              "bottom_trailing": 0,
              "top_leading": 0,
              "top_trailing": 0
            },
            "type": "rectangle"
          },
          "size": {
            "height": {
              "type": "fit",
              "value": null
            },
            "width": {
              "type": "fill",
              "value": null
            }
          },
          "spacing": 0,
          "type": "stack"
        }
      ],
      "dimension": {
        "alignment": "center",
        "distribution": "start",
        "type": "vertical"
      },
      "id": "l7Ylx2UZeA",
      "margin": {
        "bottom": 0,
        "leading": 0,
        "top": 0,
        "trailing": 0
      },
      "name": "Content",
      "padding": {
        "bottom": 0,
        "leading": 0,
        "top": 0,
        "trailing": 0
      },
      "shadow": null,
      "shape": {
        "corners": {
          "bottom_leading": 0,
          "bottom_trailing": 0,
          "top_leading": 0,
          "top_trailing": 0
        },
        "type": "rectangle"
      },
      "size": {
        "height": {
          "type": "fill",
          "value": null
        },
        "width": {
          "type": "fill",
          "value": null
        }
      },
      "spacing": 8,
      "type": "stack"
    },
    "sticky_footer": {
      "id": "UJJRRPzRuz",
      "name": "",
      "stack": {
        "background": {
          "type": "color",
          "value": {
            "light": {
              "type": "hex",
              "value": "#ffffffff"
            }
          }
        },
        "background_color": null,
        "border": null,
        "components": [
          {
            "id": "_Lxw-dy_v2",
            "name": "",
            "stack": {
              "background": {
                "type": "color",
                "value": {
                  "light": {
                    "degrees": 350,
                    "points": [
                      {
                        "color": "#1f8d73ff",
                        "percent": 0
                      },
                      {
                        "color": "#4fcba6ff",
                        "percent": 100
                      }
                    ],
                    "type": "linear"
                  }
                }
              },
              "background_color": null,
              "border": null,
              "components": [
                {
                  "background_color": null,
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#ffffffFF"
                    }
                  },
                  "font_name": null,
                  "font_size": 15,
                  "font_weight": "semibold",
                  "horizontal_alignment": "center",
                  "id": "dZ7fOPZLZ3",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fill",
                      "value": null
                    }
                  },
                  "text_lid": "uZcnB1JkxA",
                  "type": "text"
                }
              ],
              "dimension": {
                "alignment": "center",
                "distribution": "space_between",
                "type": "horizontal"
              },
              "id": "2lQWA34IVf",
              "margin": {
                "bottom": 0,
                "leading": 16,
                "top": 0,
                "trailing": 16
              },
              "name": "",
              "padding": {
                "bottom": 10,
                "leading": 8,
                "top": 10,
                "trailing": 8
              },
              "shadow": null,
              "shape": {
                "type": "pill"
              },
              "size": {
                "height": {
                  "type": "fit",
                  "value": null
                },
                "width": {
                  "type": "fill",
                  "value": null
                }
              },
              "spacing": 0,
              "type": "stack"
            },
            "type": "purchase_button"
          },
          {
            "background": null,
            "background_color": null,
            "badge": null,
            "border": null,
            "components": [
              {
                "action": {
                  "type": "restore_purchases"
                },
                "id": "fwCGCxWP-g",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555FF"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "O6lHafxB1g",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "n1dzcYoLL1",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "8yyGLAJHC1",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "type": "button"
              },
              {
                "action": {
                  "destination": "terms",
                  "sheet": null,
                  "type": "navigate_to",
                  "url": {
                    "method": "external_browser",
                    "url_lid": "92rZFECc4Z"
                  }
                },
                "id": "4O6nvR36US",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555ff"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "w9Q9OQdNhD",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "9pHXVuJRXm",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "QXi3Itf2G0",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "transition": null,
                "type": "button"
              },
              {
                "action": {
                  "destination": "privacy_policy",
                  "sheet": null,
                  "type": "navigate_to",
                  "url": {
                    "method": "external_browser",
                    "url_lid": "VBPJOj-Wkx"
                  }
                },
                "id": "rT5WcCH3Po",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555ff"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "EZRaNaklwb",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "PXTOmY0Zc3",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "NHiaJ0wCmX",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "transition": null,
                "type": "button"
              }
            ],
            "dimension": {
              "alignment": "top",
              "distribution": "center",
              "type": "horizontal"
            },
            "id": "Gfi8Is2-0L",
            "margin": {
              "bottom": 0,
              "leading": 0,
              "top": 8,
              "trailing": 0
            },
            "name": "Footer buttons",
            "padding": {
              "bottom": 0,
              "leading": 0,
              "top": 0,
              "trailing": 0
            },
            "shadow": null,
            "shape": {
              "corners": {
                "bottom_leading": 0,
                "bottom_trailing": 0,
                "top_leading": 0,
                "top_trailing": 0
              },
              "type": "rectangle"
            },
            "size": {
              "height": {
                "type": "fit",
                "value": null
              },
              "width": {
                "type": "fill",
                "value": null
              }
            },
            "spacing": 32,
            "type": "stack"
          }
        ],
        "dimension": {
          "alignment": "leading",
          "distribution": "start",
          "type": "vertical"
        },
        "id": "PXAihBeVXK",
        "margin": {
          "bottom": 0,
          "leading": 0,
          "top": 0,
          "trailing": 0
        },
        "name": "Footer",
        "padding": {
          "bottom": 0,
          "leading": 0,
          "top": 16,
          "trailing": 0
        },
        "shadow": {
          "color": {
            "light": {
              "type": "hex",
              "value": "#ccccccff"
            }
          },
          "radius": 16,
          "x": 4,
          "y": 4
        },
        "shape": {
          "corners": {
            "bottom_leading": 0,
            "bottom_trailing": 0,
            "top_leading": 16,
            "top_trailing": 16
          },
          "type": "rectangle"
        },
        "size": {
          "height": {
            "type": "fit",
            "value": null
          },
          "width": {
            "type": "fill",
            "value": null
          }
        },
        "spacing": 4,
        "type": "stack"
      },
      "type": "footer"
    }
  }
}
"""#

    static let cat = #"""
{
  "base": {
    "background": {
      "type": "color",
      "value": {
        "light": {
          "type": "hex",
          "value": "#ffffffff"
        }
      }
    },
    "header": null,
    "stack": {
      "background": null,
      "background_color": null,
      "border": null,
      "components": [
        {
          "background": null,
          "background_color": null,
          "border": null,
          "components": [
            {
              "color_overlay": {
                "light": {
                  "degrees": 180,
                  "points": [
                    {
                      "color": "#ffffff00",
                      "percent": 72
                    },
                    {
                      "color": "#ffffffff",
                      "percent": 92
                    }
                  ],
                  "type": "linear"
                }
              },
              "fit_mode": "fit",
              "id": "C3L5jrSyft",
              "mask_shape": {
                "corners": null,
                "type": "rectangle"
              },
              "name": "",
              "size": {
                "height": {
                  "type": "fit",
                  "value": null
                },
                "width": {
                  "type": "fill",
                  "value": null
                }
              },
              "source": {
                "light": {
                  "heic": "https://assets.pawwalls.com/1181742_1734515710.heic",
                  "heic_low_res": "https://assets.pawwalls.com/1181742_low_res_1734515710.heic",
                  "height": 1306,
                  "original": "https://assets.pawwalls.com/1181742_1734515710.jpg",
                  "webp": "https://assets.pawwalls.com/1181742_1734515710.webp",
                  "webp_low_res": "https://assets.pawwalls.com/1181742_low_res_1734515710.webp",
                  "width": 1959
                }
              },
              "type": "image"
            },
            {
              "action": {
                "type": "navigate_back"
              },
              "id": "bu0_nTLC8M",
              "name": "Close button",
              "stack": {
                "background": null,
                "background_color": null,
                "border": null,
                "components": [
                  {
                    "base_url": "https://icons.pawwalls.com/icons",
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "formats": {
                      "heic": "x.heic",
                      "png": "x.png",
                      "svg": "x.svg",
                      "webp": "x.webp"
                    },
                    "icon_background": {
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#ffffffff"
                        }
                      },
                      "shape": {
                        "corners": null,
                        "type": "circle"
                      }
                    },
                    "icon_name": "x",
                    "id": "g6deqj_jtH",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 2,
                      "leading": 2,
                      "top": 2,
                      "trailing": 2
                    },
                    "size": {
                      "height": {
                        "type": "fixed",
                        "value": 24
                      },
                      "width": {
                        "type": "fixed",
                        "value": 24
                      }
                    },
                    "type": "icon"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "space_between",
                  "type": "vertical"
                },
                "id": "8fu3zVJgDj",
                "margin": {
                  "bottom": 0,
                  "leading": 0,
                  "top": 16,
                  "trailing": 16
                },
                "name": "",
                "padding": {
                  "bottom": 4,
                  "leading": 4,
                  "top": 4,
                  "trailing": 4
                },
                "shadow": null,
                "shape": {
                  "corners": {
                    "bottom_leading": 0,
                    "bottom_trailing": 0,
                    "top_leading": 0,
                    "top_trailing": 0
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fit",
                    "value": null
                  }
                },
                "spacing": 0,
                "type": "stack"
              },
              "type": "button"
            }
          ],
          "dimension": {
            "alignment": "top_trailing",
            "distribution": "space_between",
            "type": "zlayer"
          },
          "id": "1G0XaOjb8n",
          "margin": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "name": "Header stack",
          "padding": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "shadow": null,
          "shape": {
            "corners": {
              "bottom_leading": 0,
              "bottom_trailing": 0,
              "top_leading": 0,
              "top_trailing": 0
            },
            "type": "rectangle"
          },
          "size": {
            "height": {
              "type": "fit",
              "value": null
            },
            "width": {
              "type": "fill",
              "value": null
            }
          },
          "spacing": 0,
          "type": "stack"
        },
        {
  "id": "test_web_view_cat",
  "type": "web_view",
  "protocol_version": 1,
  "url": "https://alexrepty.github.io/cat.html",
  "size": {
    "width": { "type": "fit" },
    "height": { "type": "fill" }
  },
  "fallback": {
    "id": "test_web_view_cat_fallback",
    "type": "stack",
    "components": [],
    "size": { "width": { "type": "fit" }, "height": { "type": "fill" } },
    "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
    "margin":  { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
  }
        },
        {
          "background": null,
          "background_color": null,
          "border": null,
          "components": [
            {
              "id": "f_ZGIReeHL",
              "is_selected_by_default": false,
              "name": "",
              "package_id": "$rc_monthly",
              "stack": {
                "background": null,
                "background_color": null,
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#d3d3d3ff"
                    }
                  },
                  "width": 1
                },
                "components": [
                  {
                    "background": null,
                    "background_color": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000ff"
                          }
                        },
                        "font_name": null,
                        "font_size": 16,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "id": "c13Mv5wrJU",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fill",
                            "value": null
                          }
                        },
                        "text_lid": "b11T5KqURa",
                        "type": "text"
                      },
                      {
                        "base_url": "https://icons.pawwalls.com/icons",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ccccccff"
                          }
                        },
                        "formats": {
                          "heic": "circle.heic",
                          "png": "circle.png",
                          "svg": "circle.svg",
                          "webp": "circle.webp"
                        },
                        "icon_background": null,
                        "icon_name": "circle",
                        "id": "SUpKRjECLa",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "overrides": [
                          {
                            "conditions": [
                              {
                                "type": "selected"
                              }
                            ],
                            "properties": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#4fcba6ff"
                                }
                              },
                              "formats": {
                                "heic": "circle-check.heic",
                                "png": "circle-check.png",
                                "svg": "circle-check.svg",
                                "webp": "circle-check.webp"
                              },
                              "icon_name": "circle-check"
                            }
                          }
                        ],
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fixed",
                            "value": 32
                          },
                          "width": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "type": "icon"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "space_between",
                      "type": "horizontal"
                    },
                    "id": "DhKZ9-WD_q",
                    "margin": {
                      "bottom": 16,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 8,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "rectangle"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "spacing": 12,
                    "type": "stack"
                  },
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "font_name": null,
                    "font_size": 16,
                    "font_weight": "bold",
                    "horizontal_alignment": "leading",
                    "id": "ahQAs554G5",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "text_lid": "3PUpQs2Ysa",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "start",
                  "type": "vertical"
                },
                "id": "ZHiZi-vIYb",
                "margin": {
                  "bottom": 4,
                  "leading": 8,
                  "top": 4,
                  "trailing": 8
                },
                "name": "",
                "overrides": [
                  {
                    "conditions": [
                      {
                        "type": "selected"
                      }
                    ],
                    "properties": {
                      "border": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba6ff"
                          }
                        },
                        "width": 1
                      },
                      "shadow": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba640"
                          }
                        },
                        "radius": 3,
                        "x": 1,
                        "y": 2
                      }
                    }
                  }
                ],
                "padding": {
                  "bottom": 8,
                  "leading": 16,
                  "top": 8,
                  "trailing": 16
                },
                "shadow": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#0505050d"
                    }
                  },
                  "radius": 3,
                  "x": 1,
                  "y": 2
                },
                "shape": {
                  "corners": {
                    "bottom_leading": 8,
                    "bottom_trailing": 8,
                    "top_leading": 8,
                    "top_trailing": 8
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fill",
                    "value": null
                  }
                },
                "spacing": 4,
                "type": "stack"
              },
              "type": "package"
            },
            {
              "id": "SNV2eGXTt5",
              "is_selected_by_default": true,
              "name": "",
              "package_id": "$rc_annual",
              "stack": {
                "background": null,
                "background_color": null,
                "badge": {
                  "alignment": "top",
                  "stack": {
                    "background": {
                      "type": "color",
                      "value": {
                        "light": {
                          "type": "hex",
                          "value": "#9ef8ddff"
                        }
                      }
                    },
                    "background_color": {
                      "light": {
                        "type": "hex",
                        "value": "#9ef8ddff"
                      }
                    },
                    "badge": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000"
                          }
                        },
                        "font_name": null,
                        "font_size": 12,
                        "font_weight": "bold",
                        "horizontal_alignment": "center",
                        "id": "0x4zA6YxaH",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fit",
                            "value": null
                          }
                        },
                        "text_lid": "pAwLNYbZ2e",
                        "type": "text"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "center",
                      "type": "vertical"
                    },
                    "id": "gjSHZJt1ey",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 4,
                      "leading": 12,
                      "top": 4,
                      "trailing": 12
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 0,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "pill"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fit",
                        "value": null
                      }
                    },
                    "spacing": 0,
                    "type": "stack"
                  },
                  "style": "overlay"
                },
                "border": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#d3d3d3ff"
                    }
                  },
                  "width": 1
                },
                "components": [
                  {
                    "background": null,
                    "background_color": null,
                    "border": null,
                    "components": [
                      {
                        "background_color": null,
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#000000"
                          }
                        },
                        "font_name": null,
                        "font_size": 16,
                        "font_weight": "regular",
                        "horizontal_alignment": "leading",
                        "id": "qCRoPQZknN",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fit",
                            "value": null
                          },
                          "width": {
                            "type": "fill",
                            "value": null
                          }
                        },
                        "text_lid": "Hjy1nCtkxJ",
                        "type": "text"
                      },
                      {
                        "base_url": "https://icons.pawwalls.com/icons",
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#ccccccff"
                          }
                        },
                        "formats": {
                          "heic": "circle.heic",
                          "png": "circle.png",
                          "svg": "circle.svg",
                          "webp": "circle.webp"
                        },
                        "icon_background": null,
                        "icon_name": "circle",
                        "id": "whelaBUPN5",
                        "margin": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "name": "",
                        "overrides": [
                          {
                            "conditions": [
                              {
                                "type": "selected"
                              }
                            ],
                            "properties": {
                              "color": {
                                "light": {
                                  "type": "hex",
                                  "value": "#4fcba6ff"
                                }
                              },
                              "formats": {
                                "heic": "circle-check.heic",
                                "png": "circle-check.png",
                                "svg": "circle-check.svg",
                                "webp": "circle-check.webp"
                              },
                              "icon_name": "circle-check"
                            }
                          }
                        ],
                        "padding": {
                          "bottom": 0,
                          "leading": 0,
                          "top": 0,
                          "trailing": 0
                        },
                        "size": {
                          "height": {
                            "type": "fixed",
                            "value": 32
                          },
                          "width": {
                            "type": "fixed",
                            "value": 32
                          }
                        },
                        "type": "icon"
                      }
                    ],
                    "dimension": {
                      "alignment": "center",
                      "distribution": "space_between",
                      "type": "horizontal"
                    },
                    "id": "and6vK3XtL",
                    "margin": {
                      "bottom": 16,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "shadow": null,
                    "shape": {
                      "corners": {
                        "bottom_leading": 0,
                        "bottom_trailing": 8,
                        "top_leading": 0,
                        "top_trailing": 0
                      },
                      "type": "rectangle"
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "spacing": 12,
                    "type": "stack"
                  },
                  {
                    "background_color": null,
                    "color": {
                      "light": {
                        "type": "hex",
                        "value": "#000000"
                      }
                    },
                    "font_name": null,
                    "font_size": 16,
                    "font_weight": "bold",
                    "horizontal_alignment": "leading",
                    "id": "hRGprKdmFd",
                    "margin": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "name": "",
                    "padding": {
                      "bottom": 0,
                      "leading": 0,
                      "top": 0,
                      "trailing": 0
                    },
                    "size": {
                      "height": {
                        "type": "fit",
                        "value": null
                      },
                      "width": {
                        "type": "fill",
                        "value": null
                      }
                    },
                    "text_lid": "tzMoZfGK7q",
                    "type": "text"
                  }
                ],
                "dimension": {
                  "alignment": "leading",
                  "distribution": "start",
                  "type": "vertical"
                },
                "id": "6esRiiY6GO",
                "margin": {
                  "bottom": 4,
                  "leading": 8,
                  "top": 4,
                  "trailing": 8
                },
                "name": "",
                "overrides": [
                  {
                    "conditions": [
                      {
                        "type": "selected"
                      }
                    ],
                    "properties": {
                      "border": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba6ff"
                          }
                        },
                        "width": 1
                      },
                      "shadow": {
                        "color": {
                          "light": {
                            "type": "hex",
                            "value": "#4fcba640"
                          }
                        },
                        "radius": 12,
                        "x": 1,
                        "y": 4
                      }
                    }
                  }
                ],
                "padding": {
                  "bottom": 8,
                  "leading": 16,
                  "top": 8,
                  "trailing": 16
                },
                "shadow": {
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#0202020d"
                    }
                  },
                  "radius": 3,
                  "x": 0,
                  "y": 2
                },
                "shape": {
                  "corners": {
                    "bottom_leading": 8,
                    "bottom_trailing": 8,
                    "top_leading": 8,
                    "top_trailing": 8
                  },
                  "type": "rectangle"
                },
                "size": {
                  "height": {
                    "type": "fit",
                    "value": null
                  },
                  "width": {
                    "type": "fill",
                    "value": null
                  }
                },
                "spacing": 4,
                "type": "stack"
              },
              "type": "package"
            }
          ],
          "dimension": {
            "alignment": "center",
            "distribution": "space_between",
            "type": "horizontal"
          },
          "id": "JivD_4KEjF",
          "margin": {
            "bottom": 0,
            "leading": 8,
            "top": 0,
            "trailing": 8
          },
          "name": "Package stack",
          "padding": {
            "bottom": 0,
            "leading": 0,
            "top": 0,
            "trailing": 0
          },
          "shadow": null,
          "shape": {
            "corners": {
              "bottom_leading": 0,
              "bottom_trailing": 0,
              "top_leading": 0,
              "top_trailing": 0
            },
            "type": "rectangle"
          },
          "size": {
            "height": {
              "type": "fit",
              "value": null
            },
            "width": {
              "type": "fill",
              "value": null
            }
          },
          "spacing": 0,
          "type": "stack"
        }
      ],
      "dimension": {
        "alignment": "center",
        "distribution": "start",
        "type": "vertical"
      },
      "id": "l7Ylx2UZeA",
      "margin": {
        "bottom": 0,
        "leading": 0,
        "top": 0,
        "trailing": 0
      },
      "name": "Content",
      "padding": {
        "bottom": 0,
        "leading": 0,
        "top": 0,
        "trailing": 0
      },
      "shadow": null,
      "shape": {
        "corners": {
          "bottom_leading": 0,
          "bottom_trailing": 0,
          "top_leading": 0,
          "top_trailing": 0
        },
        "type": "rectangle"
      },
      "size": {
        "height": {
          "type": "fill",
          "value": null
        },
        "width": {
          "type": "fill",
          "value": null
        }
      },
      "spacing": 8,
      "type": "stack"
    },
    "sticky_footer": {
      "id": "UJJRRPzRuz",
      "name": "",
      "stack": {
        "background": {
          "type": "color",
          "value": {
            "light": {
              "type": "hex",
              "value": "#ffffffff"
            }
          }
        },
        "background_color": null,
        "border": null,
        "components": [
          {
            "id": "_Lxw-dy_v2",
            "name": "",
            "stack": {
              "background": {
                "type": "color",
                "value": {
                  "light": {
                    "degrees": 350,
                    "points": [
                      {
                        "color": "#1f8d73ff",
                        "percent": 0
                      },
                      {
                        "color": "#4fcba6ff",
                        "percent": 100
                      }
                    ],
                    "type": "linear"
                  }
                }
              },
              "background_color": null,
              "border": null,
              "components": [
                {
                  "background_color": null,
                  "color": {
                    "light": {
                      "type": "hex",
                      "value": "#ffffffFF"
                    }
                  },
                  "font_name": null,
                  "font_size": 15,
                  "font_weight": "semibold",
                  "horizontal_alignment": "center",
                  "id": "dZ7fOPZLZ3",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fill",
                      "value": null
                    }
                  },
                  "text_lid": "uZcnB1JkxA",
                  "type": "text"
                }
              ],
              "dimension": {
                "alignment": "center",
                "distribution": "space_between",
                "type": "horizontal"
              },
              "id": "2lQWA34IVf",
              "margin": {
                "bottom": 0,
                "leading": 16,
                "top": 0,
                "trailing": 16
              },
              "name": "",
              "padding": {
                "bottom": 10,
                "leading": 8,
                "top": 10,
                "trailing": 8
              },
              "shadow": null,
              "shape": {
                "type": "pill"
              },
              "size": {
                "height": {
                  "type": "fit",
                  "value": null
                },
                "width": {
                  "type": "fill",
                  "value": null
                }
              },
              "spacing": 0,
              "type": "stack"
            },
            "type": "purchase_button"
          },
          {
            "background": null,
            "background_color": null,
            "badge": null,
            "border": null,
            "components": [
              {
                "action": {
                  "type": "restore_purchases"
                },
                "id": "fwCGCxWP-g",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555FF"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "O6lHafxB1g",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "n1dzcYoLL1",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "8yyGLAJHC1",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "type": "button"
              },
              {
                "action": {
                  "destination": "terms",
                  "sheet": null,
                  "type": "navigate_to",
                  "url": {
                    "method": "external_browser",
                    "url_lid": "92rZFECc4Z"
                  }
                },
                "id": "4O6nvR36US",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555ff"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "w9Q9OQdNhD",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "9pHXVuJRXm",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "QXi3Itf2G0",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "transition": null,
                "type": "button"
              },
              {
                "action": {
                  "destination": "privacy_policy",
                  "sheet": null,
                  "type": "navigate_to",
                  "url": {
                    "method": "external_browser",
                    "url_lid": "VBPJOj-Wkx"
                  }
                },
                "id": "rT5WcCH3Po",
                "name": "",
                "stack": {
                  "background": null,
                  "background_color": null,
                  "badge": null,
                  "border": null,
                  "components": [
                    {
                      "background_color": null,
                      "color": {
                        "light": {
                          "type": "hex",
                          "value": "#555555ff"
                        }
                      },
                      "font_name": null,
                      "font_size": 13,
                      "font_weight": "semibold",
                      "horizontal_alignment": "leading",
                      "id": "EZRaNaklwb",
                      "margin": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "name": "",
                      "padding": {
                        "bottom": 0,
                        "leading": 0,
                        "top": 0,
                        "trailing": 0
                      },
                      "size": {
                        "height": {
                          "type": "fit",
                          "value": null
                        },
                        "width": {
                          "type": "fit",
                          "value": null
                        }
                      },
                      "text_lid": "PXTOmY0Zc3",
                      "type": "text"
                    }
                  ],
                  "dimension": {
                    "alignment": "leading",
                    "distribution": "space_between",
                    "type": "vertical"
                  },
                  "id": "NHiaJ0wCmX",
                  "margin": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "name": "",
                  "padding": {
                    "bottom": 0,
                    "leading": 0,
                    "top": 0,
                    "trailing": 0
                  },
                  "shadow": null,
                  "shape": {
                    "corners": {
                      "bottom_leading": 0,
                      "bottom_trailing": 0,
                      "top_leading": 0,
                      "top_trailing": 0
                    },
                    "type": "rectangle"
                  },
                  "size": {
                    "height": {
                      "type": "fit",
                      "value": null
                    },
                    "width": {
                      "type": "fit",
                      "value": null
                    }
                  },
                  "spacing": 0,
                  "type": "stack"
                },
                "transition": null,
                "type": "button"
              }
            ],
            "dimension": {
              "alignment": "top",
              "distribution": "center",
              "type": "horizontal"
            },
            "id": "Gfi8Is2-0L",
            "margin": {
              "bottom": 0,
              "leading": 0,
              "top": 8,
              "trailing": 0
            },
            "name": "Footer buttons",
            "padding": {
              "bottom": 0,
              "leading": 0,
              "top": 0,
              "trailing": 0
            },
            "shadow": null,
            "shape": {
              "corners": {
                "bottom_leading": 0,
                "bottom_trailing": 0,
                "top_leading": 0,
                "top_trailing": 0
              },
              "type": "rectangle"
            },
            "size": {
              "height": {
                "type": "fit",
                "value": null
              },
              "width": {
                "type": "fill",
                "value": null
              }
            },
            "spacing": 32,
            "type": "stack"
          }
        ],
        "dimension": {
          "alignment": "leading",
          "distribution": "start",
          "type": "vertical"
        },
        "id": "PXAihBeVXK",
        "margin": {
          "bottom": 0,
          "leading": 0,
          "top": 0,
          "trailing": 0
        },
        "name": "Footer",
        "padding": {
          "bottom": 0,
          "leading": 0,
          "top": 16,
          "trailing": 0
        },
        "shadow": {
          "color": {
            "light": {
              "type": "hex",
              "value": "#ccccccff"
            }
          },
          "radius": 16,
          "x": 4,
          "y": 4
        },
        "shape": {
          "corners": {
            "bottom_leading": 0,
            "bottom_trailing": 0,
            "top_leading": 16,
            "top_trailing": 16
          },
          "type": "rectangle"
        },
        "size": {
          "height": {
            "type": "fit",
            "value": null
          },
          "width": {
            "type": "fill",
            "value": null
          }
        },
        "spacing": 4,
        "type": "stack"
      },
      "type": "footer"
    }
  }
}
"""#

}

#endif
