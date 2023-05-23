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

    func clearCache()

}

/// A type that can fetch purchased products from StoreKit 2.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasedProductsFetcher: PurchasedProductsFetcherType {

    private typealias Transactions = [StoreKit.VerificationResult<StoreKit.Transaction>]

    private let sandboxDetector: SandboxEnvironmentDetector
    private let cache: InMemoryCachedObject<Transactions>

    init(
        sandboxDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    ) {
        self.sandboxDetector = sandboxDetector
        self.cache = .init()
    }

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        var result: [PurchasedSK2Product] = []

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

        return result
    }

    func clearCache() {
        Logger.debug(Strings.offlineEntitlements.purchased_products_invalidating_cache)

        self.cache.clearCache()
    }

    private static let cacheDuration: DispatchTimeInterval = .minutes(5)

    private var transactions: Transactions {
        get async {
            if !self.cache.isCacheStale(durationInSeconds: Self.cacheDuration.seconds),
               let cache = self.cache.cachedInstance, !cache.isEmpty {
                Logger.debug(Strings.offlineEntitlements.purchased_products_returning_cache(count: cache.count))
                return cache
            }

            let result = await TimingUtil.measureAndLogIfTooSlow(
                threshold: .purchasedProducts,
                message: Strings.offlineEntitlements.purchased_products_fetching_too_slow
            ) {
                return await Self.fetchTransactions()
            }

            self.cache.cache(instance: result)
            return result
        }
    }

    private static func fetchTransactions() async -> Transactions {
        var result: Transactions = []

        Logger.debug(Strings.offlineEntitlements.purchased_products_fetching)
        for await transaction in StoreKit.Transaction.currentEntitlements {
            result.append(transaction)
        }

        return result
    }

}
