//
//  File.swift
//  
//
//  Created by Nacho Soto on 7/6/23.
//

import Foundation
import RevenueCat

#if DEBUG

internal enum TestData {

    static let productWithIntroOffer = TestStoreProduct(
        localizedTitle: "PRO monthly",
        price: 3.99,
        localizedPriceString: "$3.99",
        productIdentifier: "com.revenuecat.product",
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
        productIdentifier: "com.revenuecat.product",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: nil,
        discounts: []
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
        template: .example1,
        config: .init(
            packages: [.monthly],
            headerImageName: Self.paywallHeaderImageName
        ),
        localization: Self.localization,
        assetBaseURL: Self.paywallAssetBaseURL
    )
    static let paywallWithNoIntroOffer = PaywallData(
        template: .example1,
        config: .init(
            packages: [.annual],
            headerImageName: Self.paywallHeaderImageName
        ),
        localization: Self.localization,
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

    private static let localization: PaywallData.LocalizedConfiguration = .init(
        title: "Ignite your child's curiosity",
        subtitle: "Get access to all our educational content trusted by thousands of parents.",
        callToAction: "Continue",
        callToActionWithIntroOffer: "Continue",
        offerDetails: "{{ price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"
    )

    private static let offeringIdentifier = "offering"
    private static let paywallHeaderImageName = "cd84ac55_paywl0884b9ceb4_header_1689214657.jpg"
    private static let paywallAssetBaseURL = URL(string: "https://d2ban7feka8lu3.cloudfront.net")!

}

#endif
