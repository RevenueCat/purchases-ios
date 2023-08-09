//
//  TestData.swift
//  
//
//  Created by Nacho Soto on 7/6/23.
//

import Foundation
import RevenueCat

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
        price: 12.99,
        localizedPriceString: "$12.99",
        productIdentifier: "com.revenuecat.product_2",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .month),
        introductoryDiscount: Self.intro(7, .day)
    )
    static let annualProduct = TestStoreProduct(
        localizedTitle: "Annual",
        price: 69.49,
        localizedPriceString: "$69.49",
        productIdentifier: "com.revenuecat.product_3",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: Self.intro(14, .day)
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
        identifier: "weekly",
        packageType: .weekly,
        storeProduct: Self.weeklyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let monthlyPackage = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: Self.monthlyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let annualPackage = Package(
        identifier: "annual",
        packageType: .annual,
        storeProduct: Self.annualProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let packageWithIntroOffer = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: productWithIntroOffer.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let packageWithNoIntroOffer = Package(
        identifier: "annual",
        packageType: .annual,
        storeProduct: productWithNoIntroOffer.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let packages = [
        Self.packageWithIntroOffer,
        Self.packageWithNoIntroOffer
    ]

    static let paywallWithIntroOffer = PaywallData(
        template: .singlePackage,
        config: .init(
            packages: [.monthly],
            imageNames: [Self.paywallHeaderImageName],
            colors: .init(light: Self.lightColors, dark: Self.darkColors),
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
            privacyURL: URL(string: "https://revenuecat.com/privacy")!
        ),
        localization: Self.localization1,
        assetBaseURL: Self.paywallAssetBaseURL
    )
    static let paywallWithNoIntroOffer = PaywallData(
        template: .singlePackage,
        config: .init(
            packages: [.annual],
            imageNames: [Self.paywallHeaderImageName],
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
            template: .multiPackage,
            config: .init(
                packages: [.annual, .monthly],
                imageNames: [Self.paywallBackgroundImageName,
                             Self.paywallHeaderImageName],
                colors: .init(
                    light: .init(
                        background: "#FFFFFF",
                        foreground: "#000000",
                        callToActionBackground: "#EC807C",
                        callToActionForeground: "#FFFFFF"
                    ),
                    dark: .init(
                        background: "#000000",
                        foreground: "#FFFFFF",
                        callToActionBackground: "#ACD27A",
                        callToActionForeground: "#000000"
                    )
                ),
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

    static let lightColors: PaywallData.Configuration.Colors = .init(
        background: "#FFFFFF",
        foreground: "#000000",
        callToActionBackground: "#5CD27A",
        callToActionForeground: "#FFFFFF"
    )
    static let darkColors: PaywallData.Configuration.Colors = .init(
        background: "#000000",
        foreground: "#FFFFFF",
        callToActionBackground: "#ACD27A",
        callToActionForeground: "#000000"
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
        title: "Ignite your child's curiosity",
        subtitle: "Get access to all our educational content trusted by thousands of parents.",
        callToAction: "Purchase for {{ price }}",
        callToActionWithIntroOffer: "Purchase for {{ price_per_month }} per month",
        offerDetails: "{{ price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"
    )
    static let localization2: PaywallData.LocalizedConfiguration = .init(
        title: "Call to action for better conversion.",
        subtitle: "Lorem ipsum is simply dummy text of the printing and typesetting industry.",
        callToAction: "Subscribe for {{ price_per_month }}/mo",
        offerDetails: "{{ total_price_and_per_month }}",
        offerDetailsWithIntroOffer: "{{ total_price_and_per_month }} after {{ intro_duration }} trial"
    )
    static let paywallHeaderImageName = "9a17e0a7_1689854430..jpeg"
    static let paywallBackgroundImageName = "9a17e0a7_1689854342..jpg"
    static let paywallAssetBaseURL = URL(string: "https://d35rwhxn1vk1te.cloudfront.net")!

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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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
    func with(delay: Duration) -> Self {
        return .init { [checker = self.checker] in
            try? await Task.sleep(for: delay)

            return await checker($0)
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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

    /// Creates a copy of this `PurchaseHandler` with a delay.
    func with(delay: Duration) -> Self {
        return self.map { purchaseBlock in {
            try? await Task.sleep(for: delay)

            return try await purchaseBlock($0)
        }
        } restore: { restoreBlock in {
            try? await Task.sleep(for: delay)

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

#endif
