//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasedProductsFetcher.swift
//
//  Created by Andrés Boedo on 3/17/23.

import Foundation
import StoreKit

protocol PurchasedProductsFetcherType {

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product]

}

/// A type that can fetch purchased products from StoreKit 2.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasedProductsFetcher: PurchasedProductsFetcherType {

    private typealias Transactions = [StoreKit.VerificationResult<StoreKit.Transaction>]

    private let appStoreSync: () async throws -> Void
    private let sandboxDetector: SandboxEnvironmentDetector
    private let cache: InMemoryCachedObject<Transactions>
    private let updatesObservation: Task<Void, Never>

    init(
        appStoreSync: @escaping () async throws -> Void = PurchasedProductsFetcher.defaultAppStoreSync,
        sandboxDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    ) {
        self.appStoreSync = appStoreSync
        self.sandboxDetector = sandboxDetector
        self.cache = .init()

        self.updatesObservation = Task<Void, Never>(priority: .utility) { [cache = self.cache] in
            for await _ in StoreKit.Transaction.updates where cache.cachedInstance != nil {
                Logger.debug(Strings.offlineEntitlements.purchased_products_invalidating_cache)
                cache.clearCache()
            }
        }
    }

    deinit {
        self.updatesObservation.cancel()
    }

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        var result: [PurchasedSK2Product] = []

        let syncError: Error?
        do {
            try await self.appStoreSync()
            syncError = nil
        } catch {
            syncError = error
        }

        for transaction in await self.transactions {
            switch transaction {
            case let .unverified(transaction, verificationError):
                Logger.appleWarning(
                    Strings.offlineEntitlements.found_unverified_transactions_in_sk2(transactionID: transaction.id,
                                                                                     verificationError)
                )
            case let .verified(verifiedTransaction):
                result.append(.init(from: verifiedTransaction,
                                    sandboxEnvironmentDetector: self.sandboxDetector))
            }
        }

        if let error = syncError {
            if result.isEmpty {
                // Only throw errors when syncing with the store if there were no entitlements found
                throw error
            } else {
                Logger.appleError(error.localizedDescription)

                // If there are any entitlements, ignore the error.
                return result
            }
        } else {
            return result
        }
    }

    static let defaultAppStoreSync = AppStore.sync

    private static let cacheDuration: DispatchTimeInterval = .minutes(5)

    private var transactions: Transactions {
        get async {
            if !self.cache.isCacheStale(durationInSeconds: Self.cacheDuration.seconds),
               let cache = self.cache.cachedInstance, !cache.isEmpty {
                Logger.debug(Strings.offlineEntitlements.purchased_products_returning_cache(count: cache.count))
                return cache
            }

            var result: Transactions = []

            Logger.debug(Strings.offlineEntitlements.purchased_products_fetching)

            for await transaction in StoreKit.Transaction.currentEntitlements {
                result.append(transaction)
            }

            self.cache.cache(instance: result)
            return result
        }
    }

}
