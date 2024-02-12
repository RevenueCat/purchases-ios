//
//  TestData.swift
//  
//
//  Created by Nacho Soto on 7/6/23.
//

import Foundation
import RevenueCat
import SwiftUI

// swiftlint:disable type_body_length file_length

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal enum TestData {

    static let weeklyProduct = TestStoreProduct(
        localizedTitle: "Weekly",
        price: 1.99,
        localizedPriceString: "$1.99",
        productIdentifier: "com.revenuecat.product_1",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO weekly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .week),
        locale: Self.locale
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
        introductoryDiscount: Self.intro(7, .day),
        locale: Self.locale
    )
    static let threeMonthProduct = TestStoreProduct(
        localizedTitle: "3 months",
        price: 4.99,
        localizedPriceString: "$4.99",
        productIdentifier: "com.revenuecat.product_5",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 3, unit: .month),
        introductoryDiscount: Self.intro(7, .day),
        locale: Self.locale
    )
    static let sixMonthProduct = TestStoreProduct(
        localizedTitle: "6 months",
        price: 7.99,
        localizedPriceString: "$7.99",
        productIdentifier: "com.revenuecat.product_5",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 6, unit: .month),
        introductoryDiscount: Self.intro(7, .day),
        locale: Self.locale
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
        introductoryDiscount: Self.intro(14, .day, priceString: "$1.99"),
        locale: Self.locale
    )
    static let lifetimeProduct = TestStoreProduct(
        localizedTitle: "Lifetime",
        price: 119.49,
        localizedPriceString: "$119.49",
        productIdentifier: "com.revenuecat.product_lifetime",
        productType: .nonConsumable,
        localizedDescription: "Lifetime purchase",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: nil,
        locale: Self.locale
    )
    static let productWithIntroOffer = TestStoreProduct(
        localizedTitle: "PRO monthly",
        price: 3.99,
        localizedPriceString: "$3.99",
        productIdentifier: "com.revenuecat.product_4",
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
        ),
        discounts: [],
        locale: Self.locale
    )
    static let productWithNoIntroOffer = TestStoreProduct(
        localizedTitle: "PRO annual",
        price: 34.99,
        localizedPriceString: "$34.99",
        productIdentifier: "com.revenuecat.product_3",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: nil,
        discounts: [],
        locale: Self.locale
    )
    static let weeklyPackage = Package(
        identifier: PackageType.weekly.identifier,
        packageType: .weekly,
        storeProduct: Self.weeklyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let monthlyPackage = Package(
        identifier: PackageType.monthly.identifier,
        packageType: .monthly,
        storeProduct: Self.monthlyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let threeMonthPackage = Package(
        identifier: PackageType.threeMonth.identifier,
        packageType: .threeMonth,
        storeProduct: Self.threeMonthProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let sixMonthPackage = Package(
        identifier: PackageType.sixMonth.identifier,
        packageType: .sixMonth,
        storeProduct: Self.sixMonthProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let annualPackage = Package(
        identifier: PackageType.annual.identifier,
        packageType: .annual,
        storeProduct: Self.annualProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let customPackage = Package(
        identifier: "Custom",
        packageType: .custom,
        storeProduct: Self.annualProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let unknownPackage = Package(
        identifier: "Unknown",
        packageType: .unknown,
        storeProduct: Self.annualProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let packageWithIntroOffer = Package(
        identifier: PackageType.monthly.identifier,
        packageType: .monthly,
        storeProduct: productWithIntroOffer.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let packageWithNoIntroOffer = Package(
        identifier: PackageType.annual.identifier,
        packageType: .annual,
        storeProduct: productWithNoIntroOffer.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let lifetimePackage = Package(
        identifier: PackageType.lifetime.identifier,
        packageType: .lifetime,
        storeProduct: Self.lifetimeProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let packages = [
        Self.packageWithIntroOffer,
        Self.packageWithNoIntroOffer
    ]

    static let paywallWithIntroOffer = PaywallData(
        templateName: PaywallTemplate.template1.rawValue,
        config: .init(
            packages: [PackageType.monthly.identifier],
            images: Self.images,
            colors: .init(light: Self.lightColors, dark: Self.darkColors),
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
            privacyURL: URL(string: "https://revenuecat.com/privacy")!
        ),
        localization: Self.localization1,
        assetBaseURL: Self.paywallAssetBaseURL
    )
    static let paywallWithNoIntroOffer = PaywallData(
        templateName: PaywallTemplate.template1.rawValue,
        config: .init(
            packages: [PackageType.annual.identifier],
            images: Self.images,
            colors: .init(light: Self.lightColors, dark: Self.darkColors)
        ),
        localization: Self.localization1,
        assetBaseURL: Self.paywallAssetBaseURL,
        revision: 5
    )

    static let offeringWithIntroOffer = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Main offering",
        metadata: [:],
        paywall: Self.paywallWithIntroOffer,
        availablePackages: Self.packages
    )

    static let offeringWithNoIntroOffer = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Main offering",
        metadata: [:],
        paywall: Self.paywallWithNoIntroOffer,
        availablePackages: Self.packages
    )

    static let offeringWithMultiPackagePaywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            templateName: PaywallTemplate.template2.rawValue,
            config: .init(
                packages: [PackageType.annual.identifier, PackageType.monthly.identifier],
                images: Self.images,
                colors: .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#111111",
                        callToActionBackground: "#EC807C",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#BC66FF",
                        accent2: "#111100"
                    ),
                    dark: .init(
                        background: "#000000",
                        text1: "#EEEEEE",
                        callToActionBackground: "#ACD27A",
                        callToActionForeground: "#000000",
                        accent1: "#B022BB",
                        accent2: "#EEDDEE"
                    )
                ),
                blurredBackgroundImage: true,
                privacyURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: Self.localization2,
            assetBaseURL: Self.paywallAssetBaseURL
        ),
        availablePackages: [Self.weeklyPackage,
                            Self.monthlyPackage,
                            Self.annualPackage]
    )

    static let offeringWithSinglePackageFeaturesPaywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            templateName: PaywallTemplate.template3.rawValue,
            config: .init(
                packages: [PackageType.annual.identifier],
                images: Self.images,
                colors: .init(
                    light: .init(
                        background: "#FAFAFA",
                        text1: "#000000",
                        text2: "#2A2A2A",
                        callToActionBackground: "#222222",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#F4E971",
                        accent2: "#121212"
                    ),
                    dark: .init(
                        background: "#272727",
                        text1: "#FFFFFF",
                        text2: "#B7B7B7",
                        callToActionBackground: "#FFFFFF",
                        callToActionForeground: "#000000",
                        accent1: "#F4E971",
                        accent2: "#4A4A4A"
                    )
                ),
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: .init(
                title: "How your **free** trial works",
                callToAction: "Start",
                callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free",
                offerDetails: "Only {{ price }} per {{ sub_period }}",
                offerDetailsWithIntroOffer: "First {{ sub_offer_duration }} free, " +
                "then {{ total_price_and_per_month }}",
                features: [
                    .init(title: "Today",
                          content: "Full access to 1000+ workouts plus _free_ meal plan worth {{ price }}.",
                          iconID: "tick"),
                    .init(title: "Day 7",
                          content: "Get a reminder about when your trial is about to end.",
                          iconID: "notification"),
                    .init(title: "Day 14",
                          content: "You'll automatically get subscribed. " +
                          "Cancel anytime before if you didn't love our app.",
                          iconID: "attachment")
                ]),
            assetBaseURL: Self.paywallAssetBaseURL
        ),
        availablePackages: [Self.weeklyPackage,
                            Self.monthlyPackage,
                            Self.annualPackage]
    )

    static let offeringWithMultiPackageHorizontalPaywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            templateName: PaywallTemplate.template4.rawValue,
            config: .init(
                packages: [PackageType.monthly.identifier,
                           PackageType.sixMonth.identifier,
                           PackageType.annual.identifier],
                defaultPackage: PackageType.sixMonth.identifier,
                images: .init(
                    background: "background.jpg"
                ),
                colors: .init(
                    light: .init(
                        background: "#FFFFFF",
                        text1: "#111111",
                        text2: "#333333",
                        text3: "#999999",
                        callToActionBackground: "#06357D",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#D4B5FC",
                        accent2: "#DFDFDF"
                    ),
                    dark: .init(
                        background: "#000000",
                        text1: "#EEEEEE",
                        text2: "#DDDDDD",
                        text3: "#AAAAAA",
                        callToActionBackground: "#06957D",
                        callToActionForeground: "#FFFFFF",
                        accent1: "#06357D",
                        accent2: "#343434"
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
            assetBaseURL: Bundle.module.resourceURL ?? Bundle.module.bundleURL
        ),
        availablePackages: [TestData.monthlyPackage,
                            TestData.sixMonthPackage,
                            TestData.annualPackage,
                            TestData.lifetimePackage]
    )

    static let offeringWithTemplate5Paywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
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
                        background: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        text1: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).asPaywallColor,
                        text2: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).asPaywallColor,
                        text3: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        callToActionBackground: #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1).asPaywallColor,
                        callToActionForeground: #colorLiteral(red: 0.5315951397, green: 1, blue: 0.4162791786, alpha: 1).asPaywallColor,
                        accent1: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).asPaywallColor,
                        accent2: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1).asPaywallColor,
                        accent3: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1).asPaywallColor
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
        ),
        availablePackages: [TestData.monthlyPackage,
                            TestData.sixMonthPackage,
                            TestData.annualPackage]
    )

    static let offeringWithTemplate7Paywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            templateName: PaywallTemplate.template7.rawValue,
            config: .init(
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
                        accent1: "#A8EE76",
                        accent2: "#7676801F",
                        accent3: "#30A0F8"
                    ),
                    dark: .init(
                        background: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        text1: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).asPaywallColor,
                        text2: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).asPaywallColor,
                        text3: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).asPaywallColor,
                        callToActionBackground: #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1).asPaywallColor,
                        callToActionForeground: #colorLiteral(red: 0.5315951397, green: 1, blue: 0.4162791786, alpha: 1).asPaywallColor,
                        accent1: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).asPaywallColor,
                        accent2: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1).asPaywallColor,
                        accent3: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1).asPaywallColor
                    )
                ),
                tiers: [
                    .init(
                        id: "basic",
                        packages: [
                            TestData.threeMonthPackage.identifier,
                            TestData.lifetimePackage.identifier
                        ],
                        defaultPackage: TestData.threeMonthPackage.identifier
                    ),
                    .init(
                        id: "standard",
                        packages: [
                            TestData.weeklyPackage.identifier,
                            TestData.monthlyPackage.identifier
                        ],
                        defaultPackage: TestData.weeklyPackage.identifier
                    ),
                    .init(
                        id: "premium",
                        packages: [
                            TestData.sixMonthPackage.identifier,
                            TestData.annualPackage.identifier,
                            TestData.lifetimePackage.identifier
                        ],
                        defaultPackage: TestData.annualPackage.identifier
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
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, " +
                    "then {{ total_price_and_per_month }}",
                    features: [
                        .init(title: "Access to 10 cinematic LUTs", iconID: "tick"),
                        .init(title: "Standard fonts", iconID: "tick")
                    ],
                    tierName: "Basic"
                ),
                "standard": .init(
                    title: "Get started with our Standard plan",
                    callToAction: "{{ price_per_period }}",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
                    offerDetails: "{{ total_price_and_per_month }}",
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, " +
                    "then {{ total_price_and_per_month }}",
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
                    offerDetailsWithIntroOffer: "Free for {{ sub_offer_duration }}, " +
                    "then {{ total_price_and_per_month }}",
                    features: [
                        .init(title: "Access to all 150 of our cinematic LUTs", iconID: "tick"),
                        .init(title: "Custom design tools and transition effects", iconID: "tick"),
                        .init(title: "100+ exclusive templates", iconID: "tick")
                    ],
                    tierName: "Premium"
                )
            ],
            assetBaseURL: Self.paywallAssetBaseURL
        ),
        availablePackages: [TestData.weeklyPackage,
                            TestData.monthlyPackage,
                            TestData.sixMonthPackage,
                            TestData.threeMonthPackage,
                            TestData.annualPackage,
                            TestData.lifetimePackage]
    )

    static let offeringWithNoPaywall = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Offering",
        metadata: [:],
        paywall: nil,
        availablePackages: Self.packages
    )

    static let lightColors: PaywallData.Configuration.Colors = .init(
        background: "#FFFFFF",
        text1: "#000000",
        text2: "#B2B2B2",
        callToActionBackground: "#5CD27A",
        callToActionForeground: "#FFFFFF",
        accent1: "#BC66FF",
        accent2: "#00FF00"
    )
    static let darkColors: PaywallData.Configuration.Colors = .init(
        background: "#000000",
        text1: "#FFFFFF",
        text2: "#B2B2B2",
        callToActionBackground: "#ACD27A",
        callToActionForeground: "#000000",
        accent1: "#B022BB",
        accent2: "#FF00FF"
    )

    #if os(watchOS)
    static let colors: PaywallData.Configuration.Colors = Self.darkColors
    #elseif canImport(SwiftUI) && canImport(UIKit)
    static let colors: PaywallData.Configuration.Colors = .combine(light: Self.lightColors, dark: Self.darkColors)
    #endif

    static let customerInfo: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                },
                "entitlements": {
                }
            }
        }
        """
        )
    }()

    static let localization1: PaywallData.LocalizedConfiguration = .init(
        title: "Ignite your child's *curiosity*",
        subtitle: "Get access to all our educational content trusted by **thousands** of parents.",
        callToAction: "Purchase for {{ price }}",
        callToActionWithIntroOffer: "Purchase for {{ sub_price_per_month }} per month",
        offerDetails: "{{ sub_price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
        "then {{ sub_price_per_month }} per month",
        features: []
    )
    static let localization2: PaywallData.LocalizedConfiguration = .init(
        title: "Call to action for _better_ conversion.",
        subtitle: "Lorem ipsum is simply dummy text of the ~printing and~ typesetting industry.",
        callToAction: "Subscribe for {{ sub_price_per_month }}/mo",
        offerDetails: "{{ total_price_and_per_month }}",
        offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ sub_offer_duration }} trial",
        offerName: "{{ sub_period }}",
        features: []
    )
    static let paywallHeaderImageName = "9a17e0a7_1689854430..jpeg"
    static let paywallBackgroundImageName = "9a17e0a7_1689854342..jpg"
    static let images: PaywallData.Configuration.Images = .init(
        header: Self.paywallHeaderImageName,
        background: Self.paywallBackgroundImageName,
        icon: Self.paywallHeaderImageName
    )
    static let paywallAssetBaseURL = URL(string: "https://assets.pawwalls.com")!

    #if os(watchOS)
    // `Locale.current` in watchOS produces `en_001` when running tests
    static let locale: Locale = .init(identifier: "en_US")
    #else
    static let locale: Locale = .current
    #endif

    private static let offeringIdentifier = "offering"

    private static func intro(
        _ duration: Int,
        _ unit: SubscriptionPeriod.Unit,
        priceString: String = "$0.00"
    ) -> TestStoreProductDiscount {
        return .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: priceString,
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: duration, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
    }

}

// MARK: -

extension PaywallColor: ExpressibleByStringLiteral {

    /// Creates a `PaywallColor` with a string literal
    /// - Warning: This will crash at runtime if the string is invalid. Only for debugging purposes.
    public init(stringLiteral value: StringLiteralType) {
        // swiftlint:disable:next force_try
        try! self.init(stringRepresentation: value)
    }

}

extension PackageType {

    var identifier: String {
        return Package.string(from: self)!
    }

}

extension CustomerInfo {

    static func decode(_ json: String) -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // swiftlint:disable:next force_try
        return try! decoder.decode(Self.self, from: Data(json.utf8))
    }

}

#endif
