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

}

final class PostedTransactionCache: PostedTransactionCacheType {

    private typealias StoredTransactions = Set<String>

    private let deviceCache: DeviceCache

    init(deviceCache: DeviceCache) {
        self.deviceCache = deviceCache
    }

    func savePostedTransaction(_ transaction: StoreTransactionType) {
        self.deviceCache.update(key: CacheKey.transactions,
                                default: Set<String>()) { transactions in
            transactions.insert(transaction.transactionIdentifier)
        }
    }

    func hasPostedTransaction(_ transaction: StoreTransactionType) -> Bool {
        let transactions: StoredTransactions = self.deviceCache.value(for: CacheKey.transactions) ?? []
        return transactions.contains(transaction.transactionIdentifier)
    }

}

private extension PostedTransactionCache {

    enum CacheKey: String, DeviceCacheKeyType {

        case transactions = "com.revenuecat.cached_transaction_identifier"

    }

}
