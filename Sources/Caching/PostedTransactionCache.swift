//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostedTransactionCache.swift
//
//  Created by Nacho Soto on 7/27/23.

import Foundation

/// A type that can keep track of which transactions have been posted to the backend.
protocol PostedTransactionCacheType: Sendable {

    func savePostedTransaction(_ transaction: StoreTransactionType)
    func hasPostedTransaction(_ transaction: StoreTransactionType) -> Bool

    /// - Returns: the subset of `transactions` that have not been posted.
    func unpostedTransactions<T: StoreTransactionType>(in transactions: [T]) -> [T]

}

final class PostedTransactionCache: PostedTransactionCacheType {

    /// The format of the cache: `StoreTransactionType.transactionIdentifier` -> `Date`.
    private typealias StoredTransactions = [String: Date]

    private let deviceCache: DeviceCache
    private let clock: ClockType

    init(deviceCache: DeviceCache, clock: ClockType) {
        self.deviceCache = deviceCache
        self.clock = clock
    }

    func savePostedTransaction(_ transaction: StoreTransactionType) {
        RCIntegrationTestAssertNotMainThread()

        Logger.debug(Strings.purchase.saving_posted_transaction(transaction))

        self.deviceCache.update(key: CacheKey.transactions,
                                default: StoredTransactions()) { transactions in
            self.pruneOldTransactions(from: &transactions)
            transactions[transaction.transactionIdentifier] = self.clock.now
        }
    }

    func hasPostedTransaction(_ transaction: StoreTransactionType) -> Bool {
        RCIntegrationTestAssertNotMainThread()

        return self.storedTransactions.keys.contains(transaction.transactionIdentifier)
    }

    func unpostedTransactions<T: StoreTransactionType>(in transactions: [T]) -> [T] {
        RCIntegrationTestAssertNotMainThread()

        return Self.unpostedTransactions(in: transactions, with: self.storedTransactions.keys)
    }

    // MARK: -

    private var storedTransactions: StoredTransactions {
        return self.deviceCache.value(for: CacheKey.transactions) ?? [:]
    }

    private func pruneOldTransactions(from cache: inout StoredTransactions) {
        let removedTransactions = cache.removeAll { self.clock.durationSince($0) > Self.cacheTTL.seconds }

        if removedTransactions > 0 {
            Logger.debug(Strings.purchase.pruned_old_posted_transactions_from_cache(count: removedTransactions))
        }
    }

}

extension PostedTransactionCache {

    static let cacheTTL: DispatchTimeInterval = .days(90)

}

extension PostedTransactionCacheType {

    /// - Returns: the subset of `transactions` that aren't included in `postedTransactions`.
    static func unpostedTransactions<T: StoreTransactionType, C: Collection>(
        in transactions: [T],
        with postedTransactions: C
    ) -> [T] where C.Element == String {
        return transactions.filter { !postedTransactions.contains($0.transactionIdentifier) }
    }

}

private extension PostedTransactionCache {

    enum CacheKey: String, DeviceCacheKeyType {

        case transactions = "com.revenuecat.cached_transaction_identifier"

    }

}
