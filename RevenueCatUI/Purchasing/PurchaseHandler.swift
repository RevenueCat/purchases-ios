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

    private let purchases: PaywallPurchasesType

    /// `false` if this `PurchaseHandler` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    /// Whether a purchase or restore is currently in progress
    @Published
    fileprivate(set) var actionInProgress: Bool = false

    /// Whether a purchase was successfully completed.
    @Published
    fileprivate(set) var purchased: Bool = false

    /// When `purchased` becomes `true`, this will include the `CustomerInfo` associated to it.
    @Published
    fileprivate(set) var purchaseResult: PurchaseResultData?

    /// Whether a restore was successfully completed.
    @Published
    fileprivate(set) var restored: Bool = false

    /// When `restored` becomes `true`, this will include the `CustomerInfo` associated to it.
    @Published
    fileprivate(set) var restoredCustomerInfo: CustomerInfo?

    private var eventData: PaywallEvent.Data?

    convenience init(purchases: Purchases = .shared) {
        self.init(isConfigured: true, purchases: purchases)
    }

    init(
        isConfigured: Bool = true,
        purchases: PaywallPurchasesType
    ) {
        self.isConfigured = isConfigured
        self.purchases = purchases
    }

    static func `default`() -> Self {
        return Purchases.isConfigured ? .init() : Self.notConfigured()
    }

    private static func notConfigured() -> Self {
        return .init(isConfigured: false, purchases: NotConfiguredPurchases())
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

        let result = try await self.purchases.purchase(package: package)

        if result.userCancelled {
            self.trackCancelledPurchase()
        } else {
            withAnimation(Constants.defaultAnimation) {
                self.purchased = true
                self.purchaseResult = result
            }
        }

        return result
    }

    /// - Returns: `success` is `true` only when the resulting `CustomerInfo`
    /// had any transactions
    @MainActor
    func restorePurchases() async throws -> (info: CustomerInfo, success: Bool) {
        self.actionInProgress = true
        defer { self.actionInProgress = false }

        let customerInfo = try await self.purchases.restorePurchases()

        withAnimation(Constants.defaultAnimation) {
            self.restored = true
            self.restoredCustomerInfo = customerInfo
        }

        return (info: customerInfo,
                success: customerInfo.hasActiveSubscriptionsOrNonSubscriptions)
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) {
        self.eventData = eventData
        self.track(.impression(.init(), eventData))
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose() -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.close(.init(), data))
        self.eventData = nil
        return true
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    fileprivate func trackCancelledPurchase() -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.cancel(.init(), data))
        return true
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PurchaseHandler {

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase and restore blocks.
    func map(
        purchase: @escaping (@escaping MockPurchases.PurchaseBlock) -> MockPurchases.PurchaseBlock,
        restore: @escaping (@escaping MockPurchases.RestoreBlock) -> MockPurchases.RestoreBlock
    ) -> Self {
        return .init(
            isConfigured: self.isConfigured,
            purchases: self.purchases.map(purchase: purchase, restore: restore)
        )
    }

    func map(
        trackEvent: @escaping (@escaping MockPurchases.TrackEventBlock) -> MockPurchases.TrackEventBlock
    ) -> Self {
        return .init(
            isConfigured: self.isConfigured,
            purchases: self.purchases.map(trackEvent: trackEvent)
        )
    }

}

#endif

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PurchaseHandler {

    func track(_ event: PaywallEvent) {
        Task.detached(priority: .background) { [purchases = self.purchases] in
            await purchases.track(paywallEvent: event)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private final class NotConfiguredPurchases: PaywallPurchasesType {

    func purchase(package: Package) async throws -> PurchaseResultData {
        throw ErrorCode.configurationError
    }

    func restorePurchases() async throws -> CustomerInfo {
        throw ErrorCode.configurationError
    }

    func track(paywallEvent: PaywallEvent) async {}

}

// MARK: - Preference Keys

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct PurchasedResultPreferenceKey: PreferenceKey {

    struct PurchaseResult: Equatable {
        var transaction: StoreTransaction?
        var customerInfo: CustomerInfo

        init(data: PurchaseResultData) {
            self.transaction = data.transaction
            self.customerInfo = data.customerInfo
        }

        init?(data: PurchaseResultData?) {
            guard let data else { return nil }
            self.init(data: data)
        }
    }

    static var defaultValue: PurchaseResult?

    static func reduce(value: inout PurchaseResult?, nextValue: () -> PurchaseResult?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct RestoredCustomerInfoPreferenceKey: PreferenceKey {

    static var defaultValue: CustomerInfo?

    static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
        value = nextValue()
    }

}

// MARK: -

private extension CustomerInfo {

    var hasActiveSubscriptionsOrNonSubscriptions: Bool {
        return !self.activeSubscriptions.isEmpty || !self.nonSubscriptions.isEmpty
    }

}
