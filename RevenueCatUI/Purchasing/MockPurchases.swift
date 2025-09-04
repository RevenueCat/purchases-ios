//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPurchasesType.swift
//
//  Created by Nacho Soto on 9/12/23.

@_spi(Internal) import RevenueCat

#if DEBUG

/// An implementation of `PaywallPurchasesType` that allows creating custom blocks.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class MockPurchases: PaywallPurchasesType {

    typealias CustomerInfoBlock = @Sendable () async throws -> CustomerInfo
    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData
    typealias RestoreBlock = @Sendable () async throws -> CustomerInfo
    typealias TrackEventBlock = @Sendable (PaywallEvent) async -> Void

    private let customerInfoBlock: CustomerInfoBlock
    private let purchaseBlock: PurchaseBlock
    private let restoreBlock: RestoreBlock
    private let trackEventBlock: TrackEventBlock
    private let _purchasesAreCompletedBy: PurchasesAreCompletedBy
    let preferredLocales: [String]
    let preferredLocaleOverride: String?

    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        get { return _purchasesAreCompletedBy }
        set { _ = newValue }
    }

    let subscriptionHistoryTracker = SubscriptionHistoryTracker()

    init(
        purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat,
        preferredLocales: [String] = ["en_US"],
        preferredLocaleOverride: String? = nil,
        purchase: @escaping PurchaseBlock,
        restorePurchases: @escaping RestoreBlock,
        trackEvent: @escaping TrackEventBlock,
        customerInfo: @escaping CustomerInfoBlock
    ) {
        self.purchaseBlock = purchase
        self.restoreBlock = restorePurchases
        self.trackEventBlock = trackEvent
        self.customerInfoBlock = customerInfo
        self._purchasesAreCompletedBy = purchasesAreCompletedBy
        self.preferredLocales = preferredLocales
        self.preferredLocaleOverride = preferredLocaleOverride
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        return try await self.customerInfoBlock()
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        return try await self.purchaseBlock(package)
    }

    func purchase(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await self.purchaseBlock(package)
    }

    func restorePurchases() async throws -> CustomerInfo {
        return try await self.restoreBlock()
    }

    func track(paywallEvent: PaywallEvent) async {
        await self.trackEventBlock(paywallEvent)
    }

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func invalidateCustomerInfoCache() {
        // No-op, this is a mock implementation.
    }
#endif

#if !os(tvOS)

    func failedToLoadFontWithConfig(_ fontConfig: UIConfig.FontsConfig) {
        // No-op, this is a mock implementation.
    }

#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallPurchasesType {

    /// Creates a copy of this `PaywallPurchasesType` wrapping `purchase` and `restore`.
    func map(
        purchase: @escaping (@escaping MockPurchases.PurchaseBlock) -> MockPurchases.PurchaseBlock,
        restore: @escaping (@escaping MockPurchases.RestoreBlock) -> MockPurchases.RestoreBlock
    ) -> PaywallPurchasesType {
        return MockPurchases { package in
            try await purchase(self.purchase(package:))(package)
        } restorePurchases: {
            try await restore(self.restorePurchases)()
        } trackEvent: { event in
            await self.track(paywallEvent: event)
        } customerInfo: {
            try await self.customerInfo()
        }
    }

    /// Creates a copy of this `PaywallPurchasesType` wrapping `trackEvent`.
    func map(
        trackEvent: @escaping (@escaping MockPurchases.TrackEventBlock) -> MockPurchases.TrackEventBlock
    ) -> PaywallPurchasesType {
        return MockPurchases { package in
            try await self.purchase(package: package)
        } restorePurchases: {
            try await self.restorePurchases()
        } trackEvent: { event in
            await trackEvent(self.track(paywallEvent:))(event)
        } customerInfo: {
            try await self.customerInfo()
        }
    }

}

#endif
