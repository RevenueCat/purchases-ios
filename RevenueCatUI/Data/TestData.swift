//
//  TestData.swift
//  
//
//  Created by Nacho Soto on 7/6/23.
//

import Foundation
import RevenueCat

// swiftlint:disable type_body_length file_length

#if DEBUG

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
internal enum TestData {

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
        introductoryDiscount: Self.intro(7, .day)
    )
    static let sixMonthProduct = TestStoreProduct(
        localizedTitle: "Monthly",
        price: 34.99,
        localizedPriceString: "$34.99",
        productIdentifier: "com.revenuecat.product_5",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 6, unit: .month),
        introductoryDiscount: Self.intro(7, .day)
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
        introductoryDiscount: Self.intro(14, .day)
    )
    static let lifetimeProduct = TestStoreProduct(
        localizedTitle: "Lifetime",
        price: 119.49,
        localizedPriceString: "$119.49",
        productIdentifier: "com.revenuecat.product_lifetime",
        productType: .nonConsumable,
        localizedDescription: "Lifetime purchase",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: nil
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
        discounts: []
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
        discounts: []
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
        template: .onePackageStandard,
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
        template: .onePackageStandard,
        config: .init(
            packages: [PackageType.annual.identifier],
            images: Self.images,
            colors: .init(light: Self.lightColors, dark: Self.darkColors)
        ),
        localization: Self.localization1,
        assetBaseURL: Self.paywallAssetBaseURL
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
            template: .multiPackageBold,
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
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
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
            template: .onePackageWithFeatures,
            config: .init(
                packages: [PackageType.annual.identifier],
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
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: .init(
                title: "How your **free** trial works",
                callToAction: "Start",
                callToActionWithIntroOffer: "Start your {{ intro_duration }} free",
                offerDetails: "Only {{ price }} per {{ period }}",
                offerDetailsWithIntroOffer: "First {{ intro_duration }} free,\nthen {{ total_price_and_per_month }}",
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
            template: .multiPackageHorizontal,
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
                offerDetails: "",
                offerDetailsWithIntroOffer: "Includes {{ intro_duration }} **free** trial",
                offerName: "{{ subscription_duration }}"
            ),
            assetBaseURL: Bundle.module.resourceURL ?? Bundle.module.bundleURL
        ),
        availablePackages: [TestData.monthlyPackage,
                            TestData.sixMonthPackage,
                            TestData.annualPackage]
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

    #if canImport(SwiftUI) && canImport(UIKit)
    static let colors: PaywallData.Configuration.Colors = .combine(light: Self.lightColors, dark: Self.darkColors)
    #endif

    static let customerInfo: CustomerInfo = {
        let json = """
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

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // swiftlint:disable:next force_try
        return try! decoder.decode(CustomerInfo.self, from: Data(json.utf8))
    }()

    static let localization1: PaywallData.LocalizedConfiguration = .init(
        title: "Ignite your child's *curiosity*",
        subtitle: "Get access to all our educational content trusted by **thousands** of parents.",
        callToAction: "Purchase for {{ price }}",
        callToActionWithIntroOffer: "Purchase for {{ price_per_month }} per month",
        offerDetails: "{{ price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month",
        features: []
    )
    static let localization2: PaywallData.LocalizedConfiguration = .init(
        title: "Call to action for _better_ conversion.",
        subtitle: "Lorem ipsum is simply dummy text of the ~printing and~ typesetting industry.",
        callToAction: "Subscribe for {{ price_per_month }}/mo",
        offerDetails: "{{ total_price_and_per_month }}",
        offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ intro_duration }} trial",
        offerName: "{{ period }}",
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

    private static let offeringIdentifier = "offering"

    private static func intro(_ duration: Int, _ unit: SubscriptionPeriod.Unit) -> TestStoreProductDiscount {
        return .init(
            identifier: "intro",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: duration, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TrialOrIntroEligibilityChecker {

    /// Creates a mock `TrialOrIntroEligibilityChecker` with a constant result.
    static func producing(eligibility: @autoclosure @escaping () -> IntroEligibilityStatus) -> Self {
        return .init { packages in
            return Dictionary(
                uniqueKeysWithValues: Set(packages)
                    .map { package in
                        let result = package.storeProduct.hasIntroDiscount
                        ? eligibility()
                        : .noIntroOfferExists

                        return (package, result)
                    }
            )
        }
    }

    /// Creates a copy of this `TrialOrIntroEligibilityChecker` with a delay.
    func with(delay seconds: TimeInterval) -> Self {
        return .init { [checker = self.checker] in
            await Task.sleep(seconds: seconds)

            return await checker($0)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PurchaseHandler {

    static func mock() -> Self {
        return self.init { _ in
            return (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: false
            )
        } restorePurchases: {
            return TestData.customerInfo
        }
    }

    static func cancelling() -> Self {
        return self.init { _ in
            return (
                transaction: nil,
                customerInfo: TestData.customerInfo,
                userCancelled: true
            )
        } restorePurchases: {
            return TestData.customerInfo
        }
    }

    /// Creates a copy of this `PurchaseHandler` with a delay.
    func with(delay seconds: TimeInterval) -> Self {
        return self.map { purchaseBlock in {
            await Task.sleep(seconds: seconds)

            return try await purchaseBlock($0)
        }
        } restore: { restoreBlock in {
            await Task.sleep(seconds: seconds)

            return try await restoreBlock()
        }
        }
    }
}

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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
private extension Task where Success == Never, Failure == Never {

    static func sleep(seconds: TimeInterval) async {
        try? await Self.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

}

#endif
