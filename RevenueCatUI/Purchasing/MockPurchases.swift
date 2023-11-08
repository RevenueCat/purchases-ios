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

import RevenueCat

#if DEBUG

/// An implementation of `PaywallPurchasesType` that allows creating custom blocks.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class MockPurchases: PaywallPurchasesType {

    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData
    typealias RestoreBlock = @Sendable () async throws -> CustomerInfo
    typealias TrackEventBlock = @Sendable (PaywallEvent) async -> Void

    private let purchaseBlock: PurchaseBlock
    private let restoreBlock: RestoreBlock
    private let trackEventBlock: TrackEventBlock

    init(
        purchase: @escaping PurchaseBlock,
        restorePurchases: @escaping RestoreBlock,
        trackEvent: @escaping TrackEventBlock
    ) {
        self.purchaseBlock = purchase
        self.restoreBlock = restorePurchases
        self.trackEventBlock = trackEvent
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        return try await self.purchaseBlock(package)
    }

    func restorePurchases() async throws -> CustomerInfo {
        return try await self.restoreBlock()
    }

    func track(paywallEvent: PaywallEvent) async {
        await self.trackEventBlock(paywallEvent)
    }

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
        }
    }

}

#endif
