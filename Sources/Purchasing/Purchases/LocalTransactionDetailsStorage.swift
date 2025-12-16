//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionDetailsStorage.swift
//
//  Created by Antonio Pallares on 15/12/25.
//

import Foundation

/// Metadata stored locally for a transaction to preserve context across sessions.
internal struct LocalTransactionDetails: Codable, Sendable {

    /// The offering context when the transaction was initiated.
    let presentedOfferingContext: PresentedOfferingContext?

    /// The paywall event data when the transaction was initiated.
    let paywallPostReceiptData: PaywallEvent?

    /// Whether purchases are completed by RevenueCat or the app (observer mode equivalent).
    let observerMode: Bool

    /// The product identifier (used for SK1 pending transaction fallback).
    let productIdentifier: String

    init(
        presentedOfferingContext: PresentedOfferingContext?,
        paywallPostReceiptData: PaywallEvent?,
        observerMode: Bool,
        productIdentifier: String
    ) {
        self.presentedOfferingContext = presentedOfferingContext
        self.paywallPostReceiptData = paywallPostReceiptData
        self.observerMode = observerMode
        self.productIdentifier = productIdentifier
    }
}

/// Cache for storing local transaction details persistently on disk.
final class LocalTransactionDetailsStorage: Sendable {

    private let cache: SynchronizedLargeItemCache

    init(fileManager: LargeItemCacheType = FileManager.default) {
        self.cache = SynchronizedLargeItemCache(cache: fileManager, basePath: "revenuecat.localTransactionDetails")
    }

    /// Cache key for local transaction details.
    struct Key: DeviceCacheKeyType {
        private let identifier: String

        init(transactionIdentifier: String) {
            self.identifier = "transaction.\(transactionIdentifier)"
        }

        init(productIdentifier: String) {
            self.identifier = "product.\(productIdentifier)"
        }

        var rawValue: String {
            return "transactionDetails.\(identifier)"
        }
    }

    /// Store transaction details for a given transaction ID.
    func store(details: LocalTransactionDetails, forTransactionID transactionID: String) {
        // TODO: What if there's already details stored for the transactionID? Should we remove them?
        let key = Key(transactionIdentifier: transactionID)
        self.cache.set(codable: details, forKey: key)
    }

    /// Store transaction details for a given product ID (used for SK1 pending transactions).
    func store(details: LocalTransactionDetails, forProductID productID: String) {
        // TODO: What if there's already details stored for the productID? Should we remove them?
        let key = Key(productIdentifier: productID)
        self.cache.set(codable: details, forKey: key)
    }

    /// Retrieve transaction details for a given transaction ID.
    func retrieve(forTransactionID transactionID: String) -> LocalTransactionDetails? {
        let key = Key(transactionIdentifier: transactionID)
        return self.cache.value(forKey: key)
    }

    /// Retrieve transaction details for a given product ID (used for SK1 pending transactions).
    func retrieve(forProductID productID: String) -> LocalTransactionDetails? {
        let key = Key(productIdentifier: productID)
        return self.cache.value(forKey: key)
    }

    /// Remove transaction details for a given transaction ID.
    func remove(forTransactionID transactionID: String) {
        let key = Key(transactionIdentifier: transactionID)
        self.cache.removeObject(forKey: key)
    }

    /// Remove transaction details for a given product ID.
    func remove(forProductID productID: String) {
        let key = Key(productIdentifier: productID)
        self.cache.removeObject(forKey: key)
    }

    /// Migrate details from product ID to transaction ID (for SK1 pending → purchased transition).
    // TODO: What about SK2 pending transactions?
    func migrate(fromProductID productID: String, toTransactionID transactionID: String) {
        let oldKey = Key(productIdentifier: productID)
        let newKey = Key(transactionIdentifier: transactionID)
        self.cache.moveObject(fromKey: oldKey, toKey: newKey)
    }
}

