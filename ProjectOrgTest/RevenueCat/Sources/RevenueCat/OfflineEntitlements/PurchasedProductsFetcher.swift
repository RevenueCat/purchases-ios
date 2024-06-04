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
final class PurchasedProductsFetcher: PurchasedProductsFetcherType {

    private typealias Transactions = [StoreKit.VerificationResult<StoreKit.Transaction>]

    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let sandboxDetector: SandboxEnvironmentDetector
    private let cache: InMemoryCachedObject<Transactions>

    init(
        storeKit2TransactionFetcher: StoreKit2TransactionFetcherType = StoreKit2TransactionFetcher(),
        sandboxDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    ) {
        self.sandboxDetector = sandboxDetector
        self.transactionFetcher = storeKit2TransactionFetcher
        self.cache = .init()
    }

    func fetchPurchasedProducts() async throws -> [PurchasedSK2Product] {
        var result: [PurchasedSK2Product] = []

        for transaction in try await self.transactions {
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
        get async throws {
            if !self.cache.isCacheStale(durationInSeconds: Self.cacheDuration.seconds),
               let cache = self.cache.cachedInstance, !cache.isEmpty {
                Logger.debug(Strings.offlineEntitlements.purchased_products_returning_cache(count: cache.count))
                return cache
            }

            let result = try await TimingUtil.measureAndLogIfTooSlow(
                threshold: .purchasedProducts,
                message: Strings.offlineEntitlements.purchased_products_fetching_too_slow
            ) {
                return try await self.fetchTransactions()
            }

            self.cache.cache(instance: result)
            return result
        }
    }

    private func fetchTransactions() async throws -> Transactions {
        guard await !self.transactionFetcher.hasPendingConsumablePurchase else {
            throw Error.foundConsumablePurchase
        }

        Logger.debug(Strings.offlineEntitlements.purchased_products_fetching)
        let result = await StoreKit.Transaction.currentEntitlements.extractValues()
        Logger.debug(Strings.offlineEntitlements.purchased_products_fetched(count: result.count))

        return result
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchasedProductsFetcher: Sendable {}

// MARK: - Error

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchasedProductsFetcher {

    enum Error: Swift.Error, CustomNSError {

        case foundConsumablePurchase

        var errorUserInfo: [String: Any] {
            return [
                NSLocalizedDescriptionKey: Strings.offlineEntitlements
                    .computing_offline_customer_info_for_consumable_product.description
            ]
        }

    }

}
