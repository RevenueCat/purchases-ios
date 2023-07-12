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

    static let product1 = TestStoreProduct(
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
    static let product2 = TestStoreProduct(
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
    static let testPackage = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: product1.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )

    static let paywall = PaywallData(
        template: .example1,
        config: .init(),
        localization: .init(title: "Ignite your child's curiosity",
                            subtitle: "Get access to all our educational content trusted by thousands of parents.",
                            callToAction: "Continue",
                            offerDetails: "Start your trial, then {{price_per_month}} per month")
    )

    static let offering = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Main offering",
        metadata: [:],
        paywall: Self.paywall,
        availablePackages: [
            testPackage,
            .init(
                identifier: "annual",
                packageType: .annual,
                storeProduct: product2.toStoreProduct(),
                offeringIdentifier: Self.offeringIdentifier
            )
        ]
    )

    private static let offeringIdentifier = "offering"

}

#endif
