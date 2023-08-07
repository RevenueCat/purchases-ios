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

    init() {
        self.packages = [
            Self.weeklyPackage,
            Self.monthlyPackage,
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
        case .template1:
            return Self.template1()
        case .template2:
            return Self.template2()
        case .template3:
            return Self.template3()
        case .template4:
            return Self.template4()
        }
    }

}

// MARK: - Packages

private extension SamplePaywallLoader {

    static let weeklyPackage = Package(
        identifier: "weekly",
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
    static let sixMonthProduct = TestStoreProduct(
        localizedTitle: "Monthly",
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
            template: .template1,
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
            template: .template2,
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
                callToAction: "Subscribe for {{ sub_price_per_month }}/mo",
                offerDetails: "{{ total_price_and_per_month }}",
                offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ sub_offer_duration }} trial",
                offerName: "{{ sub_period }}"
            ),
            assetBaseURL: Self.paywallAssetBaseURL
        )
    }

    static func template3() -> PaywallData {
        return .init(
            template: .template3,
            config: .init(
                packages: [Package.string(from: .annual)!],
                images: Self.images,
                colors: .init(
                    light: .init(
                        background: "#272727",
                        text1: "#FFFFFF",
                        text2: "#B7B7B7",
                        callToActionBackground: "#FFFFFF",
                        callToActionForeground: "#000000",
                        accent1: "#F4E971"
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
            template: .template4,
            config: .init(
                packages: Array<PackageType>([.monthly, .sixMonth, .annual])
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
                offerDetails: nil,
                offerDetailsWithIntroOffer: "Includes {{ sub_offer_duration }} **free** trial",
                offerName: "{{ sub_duration }}"
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
