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
            state: [
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

