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

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension StoreView {

    /// Creates a view to load a collection of products from the App Store, and merchandise them.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall
    public init(
        offering: Offering,
        prefersPromotionalIcon: Bool = false
    ) where Icon == EmptyView, PlaceholderIcon == EmptyView {
        self.init(
            ids: offering.allProductIdentifiers,
            prefersPromotionalIcon: prefersPromotionalIcon
        )
    }

    /// Creates a view to load a collection of products from the App Store, and merchandise them using an
    /// icon and custom placeholder icon.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall
    public init(
        offering: Offering,
        prefersPromotionalIcon: Bool = false,
        @ViewBuilder icon: @escaping (Product) -> Icon,
        @ViewBuilder placeholderIcon: () -> PlaceholderIcon
    ) {
        self.init(
            ids: offering.allProductIdentifiers,
            prefersPromotionalIcon: prefersPromotionalIcon,
            icon: icon,
            placeholderIcon: placeholderIcon
        )
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SubscriptionStoreView {

    /// Creates a ``SubscriptionStoreView`` from an ``Offering``
    /// with custom marketing content.
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall
    ///
    /// - Seealso: ``CurrentOfferingSubscriptionStoreView``
    public init(
        offering: Offering,
        @ViewBuilder marketingContent: () -> (Content)
    ) {
        self.init(
            productIDs: offering.subscriptionProductIdentifiers,
            marketingContent: marketingContent
        )
    }

    /// Creates a ``SubscriptionStoreView`` from an ``Offering``
    /// that doesn't take a custom view to use for marketing content.
    ///
    /// - Seealso: ``CurrentOfferingSubscriptionStoreView``
    public init(
        offering: Offering
    ) where Content == AutomaticSubscriptionStoreMarketingContent {
        self.init(productIDs: offering.subscriptionProductIdentifiers)
    }

}

/// ``_StoreKit_SwiftUI/SubscriptionStoreView`` that displays subscription products in the current ``Offering``.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct CurrentOfferingSubscriptionStoreView<Content: View>: View {

    @State
    private var currentOffering: Offering?
    private let marketingContent: (() -> Content)?

    /// Creates a view to load all subscriptions in a subscription group from the App Store.
    ///
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall
    public init() where Content == AutomaticSubscriptionStoreMarketingContent {
        self.marketingContent = nil
    }

    /// Creates a view to load all subscriptions in a subscription group from the App Store, and merchandise
    /// them with a custom marketing content.
    ///
    /// When the user purchases products through this paywall, the `RevenueCat` SDK will handle
    /// the result automatically. All you need to do is to dismiss the paywall
    public init(@ViewBuilder marketingContent: @escaping () -> Content) {
        self.marketingContent = marketingContent
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        Group {
            if let currentOffering {
                if let marketingContent {
                    SubscriptionStoreView(offering: currentOffering,
                                          marketingContent: marketingContent)
                } else {
                    SubscriptionStoreView(offering: currentOffering)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            if let offering = try? await Purchases.shared.offerings().current {
                self.currentOffering = offering
            }
        }
    }

}

private extension Offering {

    var subscriptionProductIdentifiers: [String] {
        return self.products
            .filter { $0.productCategory == .subscription }
            .map(\.productIdentifier)
    }

    var allProductIdentifiers: [String] {
        return self.products.map(\.productIdentifier)
    }

    private var products: some Sequence<StoreProduct> {
        return self.availablePackages.lazy.map(\.storeProduct)
    }

}

#endif
