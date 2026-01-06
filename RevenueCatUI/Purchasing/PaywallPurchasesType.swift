//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPurchasesType.swift
//
//  Created by Nacho Soto on 9/12/23.

@_spi(Internal) import RevenueCat

/// A simplified protocol for the subset of `PurchasesType` needed for `RevenueCatUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol PaywallPurchasesType: Sendable {

    var purchasesAreCompletedBy: PurchasesAreCompletedBy { get }

    /// Returns the preferred locales, including the locale override if set.
    var preferredLocales: [String] { get }

    /// `preferredLocales` will always include the preferred locale override if set, so this
    /// property is only useful for reading the override value.
    var preferredLocaleOverride: String? { get }

    /// Returns a tracker of user's subscription history
    var subscriptionHistoryTracker: SubscriptionHistoryTracker { get }

    @Sendable
    func purchase(package: Package) async throws -> PurchaseResultData

    @Sendable
    func purchase(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData

    @Sendable
    func restorePurchases() async throws -> CustomerInfo

    @Sendable
    func customerInfo() async throws -> CustomerInfo

    @Sendable
    func track(paywallEvent: PaywallEvent) async

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func invalidateCustomerInfoCache()
#endif

#if !os(tvOS)

    @Sendable
    func failedToLoadFontWithConfig(_ fontConfig: UIConfig.FontsConfig)

#endif

}

extension Purchases: PaywallPurchasesType {}
