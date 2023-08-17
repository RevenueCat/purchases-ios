//
//  LoadingPaywallView.swift
//  
//
//  Created by Nacho Soto on 7/21/23.
//

import RevenueCat
import SwiftUI

/// A `PaywallView` suitable to be displayed as a loading placeholder.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@MainActor
struct LoadingPaywallView: View {

    var mode: PaywallViewMode

    var body: some View {
        LoadedOfferingPaywallView(
            offering: .init(
                identifier: Self.offeringIdentifier,
                serverDescription: "",
                metadata: [:],
                paywall: Self.defaultPaywall,
                availablePackages: Self.packages
            ),
            paywall: Self.defaultPaywall,
            template: Self.template,
            mode: self.mode,
            fonts: DefaultPaywallFontProvider(),
            introEligibility: Self.introEligibility,
            purchaseHandler: Self.purchaseHandler
        )
        .disabled(true)
        .redacted(reason: .placeholder)
    }

    private static let template: PaywallTemplate = PaywallData.defaultTemplate
    private static let defaultPaywall: PaywallData = .createDefault(with: Self.packages)

    private static let packages: [Package] = [
        Self.monthlyPackage,
        Self.weeklyPackage,
        Self.annualPackage
    ]

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private extension LoadingPaywallView {

    static let introEligibility: TrialOrIntroEligibilityChecker = .init(checker: { packages in
        return Dictionary(
            uniqueKeysWithValues: packages.map { ($0, .unknown) }
        )
    })
    static let purchaseHandler: PurchaseHandler = .init(
        purchase: { _, _ in
            fatalError("Should not be able to purchase")
        },
        restorePurchases: {
            fatalError("Should not be able to purchase")
        }
    )

    static let offeringIdentifier = "offering"
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
        subscriptionPeriod: .init(value: 1, unit: .month)
    )
    static let annualProduct = TestStoreProduct(
        localizedTitle: "Annual",
        price: 69.49,
        localizedPriceString: "$69.49",
        productIdentifier: "com.revenuecat.product_3",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year)
    )
}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(macCatalyst, unavailable)
struct LoadingPaywallView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            LoadingPaywallView(mode: mode)
                .previewDisplayName("\(mode)")
        }
    }

}

#endif
