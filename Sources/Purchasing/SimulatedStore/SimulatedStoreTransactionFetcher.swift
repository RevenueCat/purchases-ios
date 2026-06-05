//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStoreTransactionFetcher.swift
//
//  Created by Rick van der Linden on 6/4/26.

import Foundation
import StoreKit

/// Implementation of `StoreKit2TransactionFetcherType` for the Simulated Store ("Test Store").
///
/// The Simulated Store never uses StoreKit, so there are never any transactions to fetch. Every
/// member returns an empty/`nil` result.
final class SimulatedStoreTransactionFetcher: StoreKit2TransactionFetcherType {

    init() {}

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async { [] }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var hasPendingConsumablePurchase: Bool {
        get async { false }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: StoreTransaction? {
        get async { nil }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: StoreTransaction? {
        get async { nil }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var oldestVerifiedTransaction: StoreTransaction? {
        get async { nil }
    }

    var appTransactionJWS: String? {
        get async { nil }
    }

    func appTransactionJWS(_ completionHandler: @escaping (String?) -> Void) {
        completionHandler(nil)
    }

    /// Unused in Simulated Store mode: no transactions are ever posted, so no receipt is fetched.
    /// Returns an empty receipt to satisfy the protocol.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetchReceipt(containing transaction: StoreTransactionType) async -> StoreKit2Receipt {
        Logger.warn(Strings.purchase.simulated_store_unexpected_receipt_fetch)

        return .init(
            environment: .xcode,
            subscriptionStatusBySubscriptionGroupId: [:],
            transactions: [],
            bundleId: "",
            originalApplicationVersion: nil,
            originalPurchaseDate: nil
        )
    }

}
