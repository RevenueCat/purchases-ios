//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallExtensions.swift
//
//  Created by Nacho Soto on 6/6/23.

import StoreKit
import SwiftUI

#if swift(>=5.9)

// MARK: - StoreView

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension StoreView {

    /// Creates a view to load a collection of products from the App Store, and merchandise them using an
    /// icon and custom placeholder icon.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall.
    ///
    /// - Warning: In order to use StoreKit paywalls you must configure the `RevenueCat` SDK
    /// in SK2 mode using ``Configuration/Builder/with(storeKitVersion:)``.
    public static func forOffering(
        _ offering: Offering,
        prefersPromotionalIcon: Bool = false,
        @ViewBuilder icon: @escaping (Product) -> Icon,
        @ViewBuilder placeholderIcon: () -> PlaceholderIcon
    ) -> some View {
        return self
            .init(
                ids: offering.allProductIdentifiers,
                prefersPromotionalIcon: prefersPromotionalIcon,
                icon: icon,
                placeholderIcon: placeholderIcon
            )
            .handlePurchases(offering)
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension StoreView where Icon == EmptyView, PlaceholderIcon == EmptyView {

    /// Creates a view to load a collection of products from the App Store, and merchandise them.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall.
    ///
    /// - Warning: In order to use StoreKit paywalls you must configure the `RevenueCat` SDK
    /// in SK2 mode using ``Configuration/Builder/with(storeKitVersion:)``.
    public static func forOffering(
        _ offering: Offering,
        prefersPromotionalIcon: Bool = false
    ) -> some View {
        return self
            .init(
                ids: offering.allProductIdentifiers,
                prefersPromotionalIcon: prefersPromotionalIcon
            )
            .handlePurchases(offering)
    }
}

// MARK: - SubscriptionStoreView

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SubscriptionStoreView {

    /// Creates a ``SubscriptionStoreView`` from an ``Offering``
    /// with custom marketing content.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall.
    ///
    /// - Warning: In order to use StoreKit paywalls you must configure the `RevenueCat` SDK
    /// in SK2 mode using ``Configuration/Builder/with(storeKitVersion:)``.
    public static func forOffering(
        _ offering: Offering,
        @ViewBuilder marketingContent: () -> (Content)
    ) -> some View {
        return self
            .init(
                productIDs: offering.subscriptionProductIdentifiers,
                marketingContent: marketingContent
            )
            .handlePurchases(offering)
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SubscriptionStoreView where Content == AutomaticSubscriptionStoreMarketingContent {

    /// Creates a ``SubscriptionStoreView`` from an ``Offering``
    /// that doesn't take a custom view to use for marketing content.
    ///
    /// - Warning: In order to use StoreKit paywalls you must configure the `RevenueCat` SDK
    /// in SK2 mode using ``Configuration/Builder/with(storeKitVersion:)``.
    public static func forOffering(_ offering: Offering) -> some View {
        return self
            .init(productIDs: offering.subscriptionProductIdentifiers)
            .handlePurchases(offering)
    }

}

// MARK: - Private

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private extension View {

    func handlePurchases(_ offering: Offering) -> some View {
        return self
            .onInAppPurchaseStart { product in
                guard Purchases.isConfigured else { return }

                if !Purchases.shared.isStoreKit2EnabledAndAvailable {
                    Logger.appleWarning(Strings.configure.sk2_required_for_swiftui_paywalls)
                }

                // Find offering context from a matching package.
                // Packages could have the same product but each product has the same offering
                // context so that is okay if that happens.
                let offeringContext = offering.availablePackages.first {
                    $0.storeProduct.productIdentifier == product.id
                }?.presentedOfferingContext

                Purchases.shared.cachePresentedOfferingContext(
                    offeringContext ?? .init(
                        offeringIdentifier: offering.identifier
                    ),
                    productIdentifier: product.id
                )
            }
    }

}

private extension Offering {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var subscriptionProductIdentifiers: [String] {
        return self.products
            .filter { $0.productCategory == .subscription }
            // Filter out products with no subscription periods (non-subscriptions)
            .compactMap { product in
                product.subscriptionPeriod.map { period in
                    (
                        product: product,
                        period: period
                    )
                }
            }
            // Sort by subscription period
            .sorted(using: KeyPathComparator(\.period.unit.rawValue, order: .forward))
            .map(\.product.productIdentifier)
    }

    var allProductIdentifiers: [String] {
        return self.products.map(\.productIdentifier)
    }

    private var products: some Sequence<StoreProduct> {
        return self.availablePackages.lazy.map(\.storeProduct)
    }

}

#endif
