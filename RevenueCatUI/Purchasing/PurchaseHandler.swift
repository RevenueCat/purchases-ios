//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandler.swift
//  
//  Created by Nacho Soto on 7/13/23.

import RevenueCat
import StoreKit
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class PurchaseHandler: ObservableObject {

    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData
    typealias RestoreBlock = @Sendable () async throws -> CustomerInfo
    typealias TrackEventBlock = @Sendable (PaywallEvent) async -> Void

    /// `false` if this `PurchaseHandler` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    private let purchaseBlock: PurchaseBlock
    private let restoreBlock: RestoreBlock
    private let trackEventBlock: TrackEventBlock

    /// Whether a purchase or restore is currently in progress
    @Published
    fileprivate(set) var actionInProgress: Bool = false

    /// Whether a purchase was successfully completed.
    @Published
    fileprivate(set) var purchased: Bool = false

    /// When `purchased` becomes `true`, this will include the `CustomerInfo` associated to it.
    @Published
    fileprivate(set) var purchasedCustomerInfo: CustomerInfo?

    /// Whether a restore was successfully completed.
    @Published
    fileprivate(set) var restored: Bool = false

    private var eventData: PaywallEvent.Data?

    convenience init(purchases: Purchases = .shared) {
        self.init(isConfigured: true) { package in
            return try await purchases.purchase(package: package)
        } restorePurchases: {
            return try await purchases.restorePurchases()
        } trackEvent: { event in
            await purchases.track(paywallEvent: event)
        }
    }

    init(
        isConfigured: Bool = true,
        purchase: @escaping PurchaseBlock,
        restorePurchases: @escaping RestoreBlock,
        trackEvent: @escaping TrackEventBlock
    ) {
        self.isConfigured = isConfigured
        self.purchaseBlock = purchase
        self.restoreBlock = restorePurchases
        self.trackEventBlock = trackEvent
    }

    static func `default`() -> Self {
        return Purchases.isConfigured ? .init() : .notConfigured()
    }

    private static func notConfigured() -> Self {
        return .init(isConfigured: false) { _ in
            throw ErrorCode.configurationError
        } restorePurchases: {
            throw ErrorCode.configurationError
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PurchaseHandler {

    @MainActor
    func purchase(package: Package) async throws -> PurchaseResultData {
        withAnimation(Constants.fastAnimation) {
            self.actionInProgress = true
        }
        defer { self.actionInProgress = false }

        let result = try await self.purchaseBlock(package)

        if result.userCancelled {
            self.trackCancelledPurchase()
        } else {
            withAnimation(Constants.defaultAnimation) {
                self.purchased = true
                self.purchasedCustomerInfo = result.customerInfo
            }
        }

        return result
    }

    @MainActor
    func restorePurchases() async throws -> CustomerInfo {
        self.actionInProgress = true
        defer { self.actionInProgress = false }

        let result = try await self.restoreBlock()

        self.restored = true

        return result
    }

    func trackPaywallView(_ eventData: PaywallEvent.Data) {
        self.eventData = eventData
        self.track(.view(eventData))
    }

    func trackPaywallClose(_ eventData: PaywallEvent.Data) {
        self.track(.close(eventData))
    }

    fileprivate func trackCancelledPurchase() {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return
        }

        self.track(.cancel(data.withCurrentDate()))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PurchaseHandler {

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase and restore blocks.
    func map(
        purchase: @escaping (@escaping PurchaseBlock) -> PurchaseBlock,
        restore: @escaping (@escaping RestoreBlock) -> RestoreBlock
    ) -> Self {
        return .init(purchase: purchase(self.purchaseBlock),
                     restorePurchases: restore(self.restoreBlock),
                     trackEvent: self.trackEventBlock)
    }

    func map(
        trackEvent: @escaping (@escaping TrackEventBlock) -> TrackEventBlock
    ) -> Self {
        return .init(
            purchase: self.purchaseBlock,
            restorePurchases: self.restoreBlock,
            trackEvent: trackEvent(self.trackEventBlock)
        )
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PurchaseHandler {

    func track(_ event: PaywallEvent) {
        Task.detached(priority: .background) { [block = self.trackEventBlock] in
            await block(event)
        }
    }

}

// MARK: - Preference Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct PurchasedCustomerInfoPreferenceKey: PreferenceKey {

    static var defaultValue: CustomerInfo?

    static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
        value = nextValue()
    }

}

// MARK: -

private extension PaywallEvent.Data {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func withCurrentDate() -> Self {
        var copy = self
        copy.date = .now

        return copy
    }

}
