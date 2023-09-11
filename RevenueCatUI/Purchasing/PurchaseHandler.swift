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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class PurchaseHandler: ObservableObject {

    typealias PurchaseBlock = @Sendable (Package) async throws -> PurchaseResultData
    typealias RestoreBlock = @Sendable () async throws -> CustomerInfo

    /// `false` if this `PurchaseHandler` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    private let purchaseBlock: PurchaseBlock
    private let restoreBlock: RestoreBlock

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

    /// When `restored` becomes `true`, this will include the `CustomerInfo` associated to it.
    @Published
    fileprivate(set) var restoredCustomerInfo: CustomerInfo?

    convenience init(purchases: Purchases = .shared) {
        self.init(isConfigured: true) { package in
            return try await purchases.purchase(package: package)
        } restorePurchases: {
            return try await purchases.restorePurchases()
        }
    }

    init(
        isConfigured: Bool = true,
        purchase: @escaping PurchaseBlock,
        restorePurchases: @escaping RestoreBlock
    ) {
        self.isConfigured = isConfigured
        self.purchaseBlock = purchase
        self.restoreBlock = restorePurchases
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

        if !result.userCancelled {
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

        let customerInfo = try await self.restoreBlock()

        withAnimation(Constants.defaultAnimation) {
            self.restored = true
            self.restoredCustomerInfo = customerInfo
        }

        return customerInfo
    }

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase and restore blocks.
    func map(
        purchase: @escaping (@escaping PurchaseBlock) -> PurchaseBlock,
        restore: @escaping (@escaping RestoreBlock) -> RestoreBlock
    ) -> Self {
        return .init(purchase: purchase(self.purchaseBlock),
                     restorePurchases: restore(self.restoreBlock))
    }

}

// MARK: - Preference Keys

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct PurchasedCustomerInfoPreferenceKey: PreferenceKey {

    static var defaultValue: CustomerInfo?

    static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
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
