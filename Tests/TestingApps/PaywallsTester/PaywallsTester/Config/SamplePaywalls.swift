//
//  SamplePaywalls.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/27/23.
//



import Foundation
import RevenueCat
import RevenueCatUI

import UIKit

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
            availablePackages: self.packages
        )
    }

    #if PAYWALL_COMPONENTS
    func offering(with components: PaywallComponentsData) -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywallComponentsData: components,
            availablePackages: self.packages
        )
    }
    #endif

    func offeringWithDefaultPaywall() -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: nil,
            availablePackages: self.packages
        )
    }

    func offeringWithUnrecognizedPaywall() -> Offering {
        return .init(
            identifier: Self.offeringIdentifier,
            serverDescription: Self.offeringIdentifier,
            metadata: [:],
            paywall: Self.unrecognizedTemplate(),
            availablePackages: self.packages
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

    static let weeklyPackage = Package(
        identifier: Package.string(from: .weekly)!,
        packageType: .weekly,
        storeProduct: weeklyProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let monthlyPackage = Package(
        identifier: Package.string(from: .monthly)!,
        packageType: .monthly,
        storeProduct: monthlyProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let sixMonthPackage = Package(
        identifier: Package.string(from: .sixMonth)!,
        packageType: .sixMonth,
        storeProduct: sixMonthProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let threeMonthPackage = Package(
        identifier: Package.string(from: .threeMonth)!,
        packageType: .threeMonth,
        storeProduct: threeMonthProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let annualPackage = Package(
        identifier: Package.string(from: .annual)!,
        packageType: .annual,
        storeProduct: annualProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let lifetimePackage = Package(
        identifier: Package.string(from: .lifetime)!,
        packageType: .lifetime,
        storeProduct: lifetimeProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )

    static let weeklyProduct = TestStoreProduct(
        localizedTitle: "Weekly",
        price: 1.99,
        localizedPriceString: "$1.99",
        productIdentifier: "com.revenuecat.product_1",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO weekly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .week)
    )
    static let monthlyProduct = TestStoreProduct(
        localizedTitle: "Monthly",
        price: 6.99,
        localizedPriceString: "$6.99",
        productIdentifier: "com.revenuecat.product_2",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .month),
        introductoryDiscount: .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 1, unit: .week),
            numberOfPeriods: 1,
            type: .introductory
        )
    )
    static let threeMonthProduct = TestStoreProduct(
        localizedTitle: "Three Months",
        price: 16.99,
        localizedPriceString: "$16.99",
        productIdentifier: "com.revenuecat.product_9",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO 3 months",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 3, unit: .month),
        introductoryDiscount: .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 7, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
    )
    static let sixMonthProduct = TestStoreProduct(
        localizedTitle: "Six Months",
        price: 34.99,
        localizedPriceString: "$34.99",
        productIdentifier: "com.revenuecat.product_4",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 6, unit: .month),
        introductoryDiscount: .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 7, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
    )
    static let annualProduct = TestStoreProduct(
        localizedTitle: "Annual",
        price: 53.99,
        localizedPriceString: "$53.99",
        productIdentifier: "com.revenuecat.product_3",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 14, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
    )
    static let lifetimeProduct = TestStoreProduct(
        localizedTitle: "Lifetime",
        price: 119.49,
        localizedPriceString: "$119.49",
        productIdentifier: "com.revenuecat.product_lifetime",
        productType: .consumable,
        localizedDescription: "Lifetime purchase",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: nil
    )

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

    #if PAYWALL_COMPONENTS

    typealias LocaleID = PaywallComponent.LocaleID
    typealias LocalizationDictionary = PaywallComponent.LocalizationDictionary

    static func createFakePaywallComponentsData(
        components: [PaywallComponent],
        stickyFooter: PaywallComponent.StickyFooterComponent?,
        localization: [LocaleID: LocalizationDictionary]
    ) -> PaywallComponentsData {
        PaywallComponentsData(templateName: "Component Sample",
                              assetBaseURL: URL(string:"https://assets.pawwalls.com/")!,
                              componentsConfig: .init(
                                base: .init(
                                    stack: .init(components: components),
                                    stickyFooter: stickyFooter
                                )
                              ),
                              componentsLocalizations: localization,
                              revision: 0,
                              defaultLocaleIdentifier: "en_US")
    }

    internal static var fitnessComponents: PaywallComponentsData {
        return createFakePaywallComponentsData(
            components: fitnessSample,
            stickyFooter: nil,
            localization: fitnessPaywallStrings()
        )
    }

    internal static var template1Components: PaywallComponentsData {
        return createFakePaywallComponentsData(
            components: curiosity,
            stickyFooter: nil,
            localization: curiosityPaywallStrings()
        )
    }

    internal static var simpleSampleComponents: PaywallComponentsData {
        return createFakePaywallComponentsData(
            components: simpleSix,
            stickyFooter: nil,
            localization: simplePaywallStrings()
        )
    }
    
    internal static var longWithStickyFooter: PaywallComponentsData {
        return createFakePaywallComponentsData(
            components: longWithStickyFooterComponents,
            stickyFooter: stickyPurchaseButtonFooter,
            localization: curiosityPaywallStrings()
        )
    }

    static var simpleOne: [PaywallComponent] = {
            [helloWorld]
    }()

    static var simpleTwo: [PaywallComponent] = {
            [fuzzyCat]
    }()

    static var simpleThree: [PaywallComponent] = {
        let components: [PaywallComponent] = [
            .stack(.init(components:
                            [fuzzyCat, helloWorld],
                         dimension: .vertical(.center),
                         spacing: nil,
                         backgroundColor: .init(light: "#FFFFFF"), 
                         padding: .zero))]

        return components
    }()

    static var simpleFour: [PaywallComponent] = {
        let components: [PaywallComponent] = [
            .stack(.init(components:
                            [fuzzyCat, helloWorld, purchaseSimpleButton],
                         dimension: .vertical(.center),
                         spacing: nil,
                         backgroundColor: .init(light: "#FFFFFF"),
                         padding: .zero))]

        return components
    }()

    static var simpleFive: [PaywallComponent] = {
        let components: [PaywallComponent] = [
            .stack(.init(components:
                            [fuzzyCat, spacer, featureText, spacer, purchaseSimpleButton],
                         dimension: .vertical(.center),
                         spacing: nil,
                         backgroundColor: .init(light: "#FFFFFF"),
                         padding: .zero))]

        return components
    }()

    static func makePackage(packageID: String,
                            nameTextLid: String,
                            detailTextLid: String,
                            isSelectedByDefault: Bool = false) -> PaywallComponent.PackageComponent {
        let stack: PaywallComponent.StackComponent = .init(
            components: [
                .text(.init(
                    text: nameTextLid,
                    fontWeight: .bold,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero,
                    overrides: .init(
                        states: .init(
                            selected: .init(
                                color: .init(light: "#ff0000")
                            )
                        )
                    )
                )),
                .text(.init(
                    text: detailTextLid,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero,
                    overrides: .init(
                        states: .init(
                            selected: .init(
                                color: .init(light: "#ff0000")
                            )
                        )
                    )
                ))
            ],
            dimension: .vertical(.leading),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 10,
                           bottom: 10,
                           leading: 20,
                           trailing: 20),
            cornerRadiuses: .init(topLeading: 8,
                                  topTrailing: 8,
                                  bottomLeading: 8,
                                  bottomTrailing: 8),
            border: .init(color: .init(light: "#cccccc"), width: 1),
            overrides: .init(
                states: .init(
                    selected: .init(
                        border: .init(color: .init(light: "#ff0000"), width: 1)
                    )
                )
            )
        )

        return .init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            stack: stack
        )
    }

    static var simpleSixPackages: PaywallComponent = {
        return .stack(.init(
            components: [
                .stack(.init(
                    components: [
                        .package(makePackage(packageID: Package.string(from: PackageType.monthly)!,
                                    nameTextLid: "monthly_package_name",
                                    detailTextLid: "monthly_package_details")),
                        .package(makePackage(packageID: Package.string(from: PackageType.annual)!,
                                    nameTextLid: "annual_package_name",
                                    detailTextLid: "annual_package_details",
                                    isSelectedByDefault: true))
                    ],
                    spacing: 20,
                    margin: .init(top: 20, bottom: 20, leading: 20, trailing: 20)
                )),
                .purchaseButton(.init(
                    stack: .init(
                        components: [
                            // WIP: Intro offer state with "cta_intro",
                            .text(.init(
                                text: "cta",
                                fontWeight: .bold,
                                color: .init(light: "#ffffff")
                            ))
                        ],
                        backgroundColor: .init(light: "#ff0000"),
                        padding: .init(top: 15,
                                       bottom: 15,
                                       leading: 30,
                                       trailing: 30),
                        cornerRadiuses: .init(topLeading: 16,
                                              topTrailing: 16,
                                              bottomLeading: 16,
                                              bottomTrailing: 16)
                    )
                ))
            ],
            width: .init(type: .fill, value: nil),
            backgroundColor: nil,
            margin: .init(top: 0, bottom: 0, leading: 20, trailing: 20)
        ))
    }()

    static var conditionsText1: PaywallComponent = PaywallComponent.text(
        .init(
            text: "condition_1_default",
            color: .init(light: "#000000"),
            overrides: .init(
                conditions: .init(
                    medium: .init(
                        text: "condition_1_medium"
                    )
                )
            )
        )
    )

    static var conditionsText2: PaywallComponent = PaywallComponent.text(
        .init(
            text: "condition_2_default",
            color: .init(light: "#000000"),
            overrides: .init(
                conditions: .init(
                    medium: .init(
                        visible: false
                    )
                )
            )
        )
    )

    static var simpleSix: [PaywallComponent] = {
        let components: [PaywallComponent] = [
            .stack(.init(components:
                            [
                                fuzzyCat,
                                spacer,
                                conditionsText1,
                                conditionsText2,
                                simpleFeatureStack(text: featureText),
                                spacer,
                                simpleSixPackages
                            ],
                         dimension: .vertical(.center),
                         spacing: nil,
                         backgroundColor: .init(light: "#FFFFFF"),
                         padding: .zero))]

        return components
    }()

    static var simpleSample: [PaywallComponent] = {
        let components: [PaywallComponent] = [
            .stack(.init(components:
                            //[fuzzyCat, spacer, simpleFeatureStack, spacer, purchaseSimpleButton],
                            [helloWorld, helloWorld],
                         dimension: .vertical(.center),
                         spacing: nil,
                         backgroundColor: .init(light: "#FFFFFF"),
                         padding: .zero))]

        return components

    }()

    static var triStacked: PaywallComponent = {
        .stack(.init(components:
                        [helloWorld, helloWorld, helloWorld],
                     dimension: .vertical(.center),
                     spacing: nil,
                     backgroundColor: .init(light: "#FFFFFF"),
                     padding: .zero))
    }()

    static var fuzzyCat: PaywallComponent = {
        .image(.init(source: fuzzyCatImageSource))
    }()



    static var checkmarkImage: PaywallComponent = {
        .image(.init(source: imageSource,
                     maxHeight: 20))
    }()


    static func simpleFeatureStack(text: PaywallComponent) -> PaywallComponent {
        .stack(.init(components: [checkmarkImage, text],
                     dimension: .horizontal(.center, .start),
                     spacing: nil,
                     backgroundColor: nil,
                     padding: PaywallComponent.Padding(top: 0, bottom: 0, leading: 40, trailing: 40)))
    }

    static var featureText: PaywallComponent = {
        .text(.init(
            text: "feature_text",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .body
        ))
    }()

    static var helloWorld: PaywallComponent = {
        .text(.init(
            text: "welcome_message",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .body
        ))
    }()

    static var purchaseSimpleButton: PaywallComponent = {
        .linkButton(.init(url: URL(string: "https://pay.rev.cat/d1db8380eeb98a92/josh")!,
                      textComponent: purchaseSimpleNowText))
    }()

    static var purchaseSimpleNowText: PaywallComponent.TextComponent = {
        .init(
            text: "purchase_button_text",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            backgroundColor: .init(light: "#9EE5FF"),
            padding: .init(top: 10, bottom: 10, leading: 50, trailing: 50),
            textStyle: .body
        )
    }()

    // fitness

    static var fitnessSample: [PaywallComponent] = {
        let components: [PaywallComponent] = [.stack(.init(components: [gymZStack,
                                   featureImageStack1,
                                   featureImageStack2,
                                   featureImageStack3,
                                   purchaseFitnessButton,
                                   fitnessFooter],
                      dimension: .vertical(.center),
                      spacing: 25,
                      backgroundColor: .init(light: "#000000"),
                      padding: .zero))]



        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(components)

            // Convert JSON data to a string if needed for debugging or logging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON Representation:\n\(jsonString)")
            }

            // Return components as usual
            return components
        } catch {
            print("Failed to encode components: \(error)")
            return components
        }

    }()

    static var gymZStack: PaywallComponent = {
        .stack(.init(components: [homeGym, headlineText],
                     dimension: .zlayer(.bottom),
                      spacing: 0,
                      backgroundColor: nil,
                      padding: .zero))

    }()

    static var imageURL = URL(string: "https://assets.pawwalls.com/1075077_1724796818.jpeg")!

    static var imageSource: PaywallComponent.ThemeImageUrls = .init(
        light: .init(original: imageURL, heic: imageURL, heicLowRes: imageURL)
    )

    static var treadmill: PaywallComponent = {
        .image(.init(source: imageSource,
                     fitMode: .fit,
                     maxHeight: 125,
                     cornerRadiuses: .init(topLeading: 23,
                                           topTrailing: 23,
                                           bottomLeading: 23,
                                           bottomTrailing: 23)))
    }()

    static var cycle: PaywallComponent = {
        .image(.init(source: imageSource,
                     fitMode: .fit,
                     maxHeight: 125,
                     cornerRadiuses: .init(topLeading: 23,
                                         topTrailing: 23,
                                         bottomLeading: 23,
                                         bottomTrailing: 23)))
    }()

    static var homeGym: PaywallComponent = {
        .image(.init(source: imageSource,
                     fitMode: .fill,
                     maxHeight: 200,
                     gradientColors: ["#FF000000", "#FF000000", "#00000000"]))
    }()

    static var weights: PaywallComponent = {
        .image(.init(source: imageSource,
                     fitMode: .fit,
                     maxHeight: 125,
                     cornerRadiuses: .init(topLeading: 23,
                                           topTrailing: 23,
                                           bottomLeading: 23,
                                           bottomTrailing: 23)))
    }()


    static var headlineText: PaywallComponent = {
        .text(.init(
            text: "fitness_coach_title",
            fontFamily: "",
            fontWeight: .black,
            color: .init(light: "#EE4444"),
            padding: .init(top: 0, bottom: 10, leading: 0, trailing: 0),
            textStyle: .largeTitle
        ))
    }()


    static var treadmillText: PaywallComponent = {
        .text(.init(
            text: "fitness_new_workouts",
            fontFamily: "",
            fontWeight: .semibold,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .title2
        ))
    }()

    static var cycleText: PaywallComponent = {
        .text(.init(
            text: "fitness_challenge_text",
            fontFamily: "",
            fontWeight: .semibold,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .title2
        ))
    }()

    static var weightsText: PaywallComponent = {
        .text(.init(
            text: "fitness_conquer_goals",
            fontFamily: "",
            fontWeight: .semibold,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .title2
        ))
    }()


    static var featureImageStack1: PaywallComponent = {
        .stack(.init(components: [treadmillText, spacer, treadmill, spacer],
                     dimension: .horizontal(.center, .start),
                     spacing: nil,
                     backgroundColor: nil,
                     padding: PaywallComponent.Padding(top: 0, bottom: 0, leading: 40, trailing: 40)))
    }()

    static var featureImageStack2: PaywallComponent = {
        .stack(.init(components: [spacer, cycle, spacer, cycleText],
                     dimension: .horizontal(.center, .start),
                     spacing: nil,
                     backgroundColor: nil,
                     padding: PaywallComponent.Padding(top: 0, bottom: 0, leading: 40, trailing: 40)))
    }()

    static var featureImageStack3: PaywallComponent = {
        .stack(.init(components: [weightsText, spacer, weights, spacer],
                     dimension: .horizontal(.center, .start),
                     spacing: nil,
                     backgroundColor: nil,
                     padding: PaywallComponent.Padding(top: 0, bottom: 0, leading: 40, trailing: 40)))
    }()

    static var purchaseFitnessButton: PaywallComponent = {
        .linkButton(.init(url: URL(string: "https://pay.rev.cat/d1db8380eeb98a92/josh")!,
                      textComponent: purchaseFitnessNowText))
    }()

    static var purchaseFitnessNowText: PaywallComponent.TextComponent = {
        .init(
            text: "fitness_start_today",
            fontWeight: .semibold,
            color: .init(light: "#FFFFFF"),
            backgroundColor: .init(light: "#DD4444"),
            padding: .init(top: 10, bottom: 10, leading: 50, trailing: 50),
            textStyle: .title3
        )
    }()

    static var fitnessFooter: PaywallComponent = {
        .stack(.init(components: [spacer, restoreFitnessPurchases, bulletFitness, termsAndConditionsFitness, spacer],
                      dimension: .horizontal(),
                     spacing: 10,
                     backgroundColor: nil,
                     padding: .zero))

    }()

    static var restoreFitnessPurchases: PaywallComponent = {
        .text(.init(
            text: "restore_purchases",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .caption
        ))
    }()

    static var bulletFitness: PaywallComponent = {
        .text(.init(
            text: "bullet_point",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .caption
        ))
    }()

    static var termsAndConditionsFitness: PaywallComponent = {
        .text(.init(
            text: "terms_and_conditions",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#FFFFFF"),
            padding: .zero,
            textStyle: .caption
        ))
    }()


    // CURIOSITY


    static var curiosity: [PaywallComponent] = {
        [.stack(.init(components: [headerZStack,
                                   spacer,
                                   headingText,
                                   subHeadingText,
                                   spacer,
                                   featureVStack,
                                   spacer,
                                   costText,
                                   purchaseButton,
                                   footerStack],
                      dimension: .vertical(),
                      spacing: nil,
                      backgroundColor: nil,
                      padding: .zero))]

    }()



    static var headerImage: PaywallComponent = {
        .image(.init(source: curiousKidImageSource))
    }()

    static let fuzzyCatImageURL = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let curiousKidImageURL = URL(string: "https://assets.pawwalls.com/9a17e0a7_1689854430..jpeg")!

    static var fuzzyCatImageSource: PaywallComponent.ThemeImageUrls = .init(
        light: .init(original: fuzzyCatImageURL, heic: fuzzyCatImageURL, heicLowRes: fuzzyCatImageURL)
    )
    static var curiousKidImageSource: PaywallComponent.ThemeImageUrls = .init(
        light: .init(original: curiousKidImageURL, heic: curiousKidImageURL, heicLowRes: curiousKidImageURL)
    )


    static var myGreatAppText: PaywallComponent = {
        .text(.init(
            text: "explore_button_text",
            fontFamily: "",
            fontWeight: .semibold,
            color: .init(light: "#f7d216"),
            padding: .init(top: 20, bottom: 0, leading: 20, trailing: 0),
            textStyle: .title
        ))
    }()

    static var myGreatAppTextOffset: PaywallComponent = {
        .text(.init(
            text: "explore_button_text",
            fontFamily: "",
            fontWeight: .semibold,
            color: .init(light: "#633306"),
            padding: .init(top: 21, bottom: 0, leading: 21, trailing: 0),
            textStyle: .title
        ))
    }()

    static var headerZStack: PaywallComponent = {
        .stack(.init(components: [headerImage, myGreatAppTextOffset, myGreatAppText],
                      dimension: .zlayer(.topLeading),
                      spacing: 0,
                      backgroundColor: nil,
                     padding: .zero))

    }()

    static var headingText: PaywallComponent = {
        .text(.init(
            text: "curiosity_headline",
            fontWeight: .heavy,
            color: .init(light: "#000000"),
            textStyle: .extraLargeTitle
        ))
    }()

    static var subHeadingText: PaywallComponent = {
        .text(.init(
            text: "curiosity_subheadline",
            color: .init(light: "#000000"),
            textStyle: .headline
        ))
    }()

    static var featureVStack: PaywallComponent = {
        .stack(.init(components: [feature1Text, feature2Text, feature3Text],
                     dimension: .vertical(.leading),
                     width: .init(type: .fit, value: nil),
                     spacing: 0,
                     backgroundColor: nil,
                     padding: .zero,
                     margin: .init(top: 0, bottom: 0, leading: 40, trailing: 40)))

    }()

    static var feature1Text: PaywallComponent = {
        .text(.init(
            text: "feature_valuable",
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .headline,
            horizontalAlignment: .leading
        ))
    }()

    static var feature2Text: PaywallComponent = {
        .text(.init(
            text: "feature_great_price",
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .headline,
            horizontalAlignment: .leading
        ))
    }()

    static var feature3Text: PaywallComponent = {
        .text(.init(
            text: "feature_support",
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .headline,
            horizontalAlignment: .leading
        ))
    }()

    static var costText: PaywallComponent = {
        .text(.init(
            text: "subscription_price",
            color: .init(light: "#000000"),
            textStyle: .subheadline
        ))
    }()

    static var purchaseButton: PaywallComponent = {
        .linkButton(.init(url: URL(string: "https://pay.rev.cat/d1db8380eeb98a92/josh")!,
                      textComponent: purchaseNowText))
    }()

    static var purchaseNowText: PaywallComponent.TextComponent = {
        .init(
            text: "purchase_for_price",
            fontWeight: .semibold,
            color: .init(light: "#FFFFFF"),
            backgroundColor: .init(light: "#00AA00"),
            padding: .init(top: 10, bottom: 10, leading: 100, trailing: 100),
            textStyle: .title3
        )
    }()

    static var restorePurchases: PaywallComponent = {
        .text(.init(
            text: "restore_purchases",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            padding: .zero, 
            textStyle: .caption
        ))
    }()

    static var termsAndConditions: PaywallComponent = {
        .text(.init(
            text: "terms_and_conditions",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            padding: .zero, 
            textStyle: .caption
        ))
    }()

    static var bullet: PaywallComponent = {
        .text(.init(
            text: "bullet_point",
            fontFamily: "",
            fontWeight: .regular,
            color: .init(light: "#000000"),
            padding: .zero,
            textStyle: .caption
        ))
    }()

    static var footerStack: PaywallComponent = {
        .stack(.init(components: [spacer, restorePurchases, bullet, termsAndConditions, spacer],
                      dimension: .horizontal(),
                     spacing: 10,
                     backgroundColor: nil,
                     padding: .zero))

    }()


    static var spacer: PaywallComponent = {
        .spacer(PaywallComponent.SpacerComponent())
    }()

    static var mainVStack: [PaywallComponent] = {
        [.stack(.init(components: imageZStack + twoHorizontal + [button],
                      dimension: .vertical(),
                      spacing: 0,
                      backgroundColor: nil,
                      padding: .zero))]

    }()

    static var twoHorizontal: [PaywallComponent] = {
        [.stack(.init(components: [verticalTextStack, middleText, verticalTextStack],
                      dimension: .horizontal(),
                      spacing: nil,
                      backgroundColor: .init(light: "#1122AA"),
                      padding: .zero))]

    }()

    static var verticalTextStack: PaywallComponent = {
        .stack(.init(components: [getStartedText, spacer, upgradeText],
                     dimension: .vertical(.leading),
                     spacing: nil,
                     backgroundColor: .init(light: "#11AA22"),
                     padding: .zero))

    }()

    static var middleText: PaywallComponent = {
        .text(.init(
            text: "popular_plan_label",
            color: .init(light: "#000000"),
            textStyle: .body
        ))
    }()

    static var getStartedText: PaywallComponent = {
        .text(.init(
            text: "get_started_text",
            color: .init(light: "#FF0000"),
            backgroundColor: .init(light: "#FF00FF"),
            textStyle: .body
        ))
    }()

    static var upgradeText: PaywallComponent = {
        .text(.init(
            text: "upgrade_plan_text",
            color: .init(light: "#000000"),
            backgroundColor: .init(light: "#FF00FF"),
            textStyle: .body
        ))
    }()



    static var button: PaywallComponent = {
        .linkButton(.init(url: URL(string: "https://pay.rev.cat/d1db8380eeb98a92/josh")!,
                      textComponent: purchaseNowText))
    }()




    static var imageZStack: [PaywallComponent] = {
        [.stack(.init(components: [headerImage, .text(purchaseNowText)],
                      dimension: .zlayer(.center),
                      spacing: 0,
                      backgroundColor: nil,
                      padding: .zero))]

    }()
    
    // Long with sticky footer
    
    static var longWithStickyFooterComponents: [PaywallComponent] = {
        [
            .stack(
                .init(
                    components: [
                        headerZStack,
                        spacer,
                        headingText,
                        subHeadingText,
                        spacer,
                        featureVStack,
                        spacer,
                        featureVStack,
                        spacer,
                        featureVStack,
                        spacer,
                        featureVStack,
                        spacer,
                        featureVStack,
                        spacer,
                    ],
                    dimension: .vertical(),
                    spacing: nil,
                    backgroundColor: nil,
                    padding: .zero
                )
            )
        ]
    }()
    
    static var stickyPurchaseButtonFooter: PaywallComponent.StickyFooterComponent = {
        PaywallComponent.StickyFooterComponent(
            stack: .init(
                components: [
                    costText,
                    purchaseButton,
                    footerStack
                ],
                dimension: .vertical(),
                spacing: 10,
                backgroundColor: .init(light: "#F2545B"),
                padding: .zero,
                cornerRadiuses: .init(topLeading: 16.0, topTrailing: 16.0, bottomLeading: 0.0, bottomTrailing: 0.0),
                shadow: PaywallComponent.Shadow(color: .init(light: "#000000"), radius: 8, x: 0, y: 0)
            )
        )
    }()

    static func fitnessPaywallStrings() -> [LocaleID: LocalizationDictionary] {
        return [
            "en_US": [
                "fitness_coach_title": .string("Fitness Coach"),
                "fitness_new_workouts": .string("New workouts added every day"),
                "fitness_challenge_text": .string("Challenge others and climb the leader ladder"),
                "fitness_conquer_goals": .string("Conquer your goals"),
                "fitness_start_today": .string("Start Today for $9.99/mo"),
                "restore_purchases": .string("Restore purchases"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Terms and conditions")
            ],
            "fr_FR": [
                "fitness_coach_title": .string("Coach Fitness"),
                "fitness_new_workouts": .string("Nouveaux entraînements ajoutés chaque jour"),
                "fitness_challenge_text": .string("Défiez les autres et grimpez l'échelle des leaders"),
                "fitness_conquer_goals": .string("Conquérir vos objectifs"),
                "fitness_start_today": .string("Commencez aujourd'hui pour 9,99€/mois"),
                "restore_purchases": .string("Restaurer les achats"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Conditions générales")
            ],
            "es_ES": [
                "fitness_coach_title": .string("Entrenador de fitness"),
                "fitness_new_workouts": .string("Nuevos entrenamientos añadidos todos los días"),
                "fitness_challenge_text": .string("Desafía a otros y escala en la clasificación"),
                "fitness_conquer_goals": .string("Conquista tus objetivos"),
                "fitness_start_today": .string("Comienza hoy por 9,99€/mes"),
                "restore_purchases": .string("Restaurar compras"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Términos y condiciones")
            ]
        ]
    }

    static func curiosityPaywallStrings() -> [LocaleID: LocalizationDictionary] {
        return [
            "en_US": [
                "curiosity_headline": .string("Ignite your child's curiosity"),
                "curiosity_subheadline": .string("Get access to all our educational content trusted by thousands of parents."),
                "feature_valuable": .string("✅ Valuable features"),
                "feature_great_price": .string("✅ Great Price"),
                "feature_support": .string("✅ Support"),
                "subscription_price": .string("$6.99 per month"),
                "purchase_for_price": .string("Purchase for $6.99"),
                "popular_plan_label": .string("Popular Plan"),
                "get_started_text": .string("Get started with our plan"),
                "upgrade_plan_text": .string("Upgrade to our premium plan"),
                "explore_button_text": .string("Explore"),
                "restore_purchases": .string("Restore purchases"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Terms and conditions"),
            ],
            "fr_FR": [
                "curiosity_headline": .string("Éveillez la curiosité de votre enfant"),
                "curiosity_subheadline": .string("Accédez à tout notre contenu éducatif approuvé par des milliers de parents."),
                "feature_valuable": .string("✅ Fonctionnalités précieuses"),
                "feature_great_price": .string("✅ Excellent prix"),
                "feature_support": .string("✅ Support"),
                "subscription_price": .string("6,99€ par mois"),
                "purchase_for_price": .string("Achetez pour 6,99€"),
                "popular_plan_label": .string("Plan populaire"),
                "get_started_text": .string("Commencez avec notre plan"),
                "upgrade_plan_text": .string("Passez à notre plan premium"),
                "explore_button_text": .string("Explorer"),
                "restore_purchases": .string("Restaurer les achats"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Conditions générales"),
            ],
            "es_ES": [
                "curiosity_headline": .string("Despierta la curiosidad de tu hijo"),
                "curiosity_subheadline": .string("Accede a todo nuestro contenido educativo confiado por miles de padres."),
                "feature_valuable": .string("✅ Funciones valiosas"),
                "feature_great_price": .string("✅ Gran precio"),
                "feature_support": .string("✅ Soporte"),
                "subscription_price": .string("6,99€ por mes"),
                "purchase_for_price": .string("Compra por 6,99€"),
                "popular_plan_label": .string("Plan popular"),
                "get_started_text": .string("Empieza con nuestro plan"),
                "upgrade_plan_text": .string("Actualiza a nuestro plan premium"),
                "explore_button_text": .string("Explorar"),
                "restore_purchases": .string("Restaurar compras"),
                "bullet_point": .string("•"),
                "terms_and_conditions": .string("Términos y condiciones")
            ]
        ]
    }


    static func simplePaywallStrings() -> [LocaleID: LocalizationDictionary] {
        return [
            "en_US": [
                "welcome_message": .string("Hello, Paywall Components!"),
                "purchase_button_text": .string("Purchase Now! $19.99/year"),
                "explore_button_text": .string("Explore"),
                "popular_plan_label": .string("Popular Plan"),
                "get_started_text": .string("Get started with our plan"),
                "upgrade_plan_text": .string("Upgrade to our premium plan"),
                "feature_text": .string("Feature"),
                "monthly_package_name": .string("Monthly"),
                "monthly_package_details": .string("Get now for $2.99/month"),
                "annual_package_name": .string("Annual"),
                "annual_package_details": .string("Get now for $19.99/month"),
                "cta": .string("Purchase now"),
                "cta_intro": .string("Claim free trial"),

                "condition_1_default": .string("Showing in portrait"),
                "condition_1_medium": .string("Showing in landscape"),
                "condition_2_default": .string("Should only show in portrait")
            ],
            "fr_FR": [
                "welcome_message": .string("Bonjour, Composants Paywall!"),
                "purchase_button_text": .string("Achetez maintenant! 19,99$/an"),
                "explore_button_text": .string("Explorer"),
                "popular_plan_label": .string("Plan populaire"),
                "get_started_text": .string("Commencez avec notre plan"),
                "upgrade_plan_text": .string("Passez à notre plan premium"),
                "feature_text": .string("Fonctionnalité"),
                "monthly_package_name": .string("Monthly Package FRENCH"),
                "monthly_package_details": .string("Monthly DETAILS Package"),
                "annual_package_name": .string("Annua FRENCH"),
                "annual_package_details": .string("Get now for $19.99/month FRENCH"),
                "cta": .string("Purchase now FRENCH"),
                "cta_intro": .string("Claim free trial FRENCH"),

                "condition_1_default": .string("Showing in portrait IN FRENCH"),
                "condition_1_medium": .string("Showing in landscape IN FRENCH"),
                "condition_2_default": .string("Should only show in portrait IN FRENCH")
            ],
            "es_ES": [
                "welcome_message": .string("¡Hola, Componentes Paywall!"),
                "purchase_button_text": .string("¡Compra ahora! 19,99€/año"),
                "explore_button_text": .string("Explorar"),
                "popular_plan_label": .string("Plan popular"),
                "get_started_text": .string("Empieza con nuestro plan"),
                "upgrade_plan_text": .string("Actualiza a nuestro plan premium"),
                "feature_text": .string("Función"),
                "monthly_package_name": .string("Monthly Package SPANISH"),
                "monthly_package_details": .string("Monthly DETAILS Package"),
                "annual_package_name": .string("Annual SPANISH"),
                "annual_package_details": .string("Get now for $19.99/month SPANISH"),
                "cta": .string("Purchase now SPANISH"),
                "cta_intro": .string("Claim free trial SPANISH"),

                "condition_1_default": .string("Showing in portrait IN SPANISH"),
                "condition_1_medium": .string("Showing in landscape IN SPANISH"),
                "condition_2_default": .string("Should only show in portrait IN SPANISH")
            ]
        ]
    }






    #endif

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

