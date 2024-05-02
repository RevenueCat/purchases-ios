//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModePurchaseDetector.swift
//
//  Created by Will Taylor on 5/1/24.

import Foundation
import StoreKit

/// Protocol describing an actor capable of detecting purchases from StoreKit 2.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol SK2ObserverModePurchaseDetectorType {
    func detectUnobservedTransactions(
        delegate: StoreKit2ObserverModeManagerDelegate?
    ) async
}

/// Actor responsibile for detecting purchases from StoreKit2 that should be processed by observer mode.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
actor StoreKit2ObserverModePurchaseDetector: SK2ObserverModePurchaseDetectorType {

    private let deviceCache: DeviceCache
    private let currentUserProvider: CurrentUserProvider
    private let allTransactionsProvider: AllTransactionsProviderType

    init(
        deviceCache: DeviceCache,
        currentUserProvider: CurrentUserProvider,
        allTransactionsProvider: AllTransactionsProviderType
    ) {
        self.deviceCache = deviceCache
        self.currentUserProvider = currentUserProvider
        self.allTransactionsProvider = allTransactionsProvider
    }

    /// Detects unobserved transactions and forwards them to the StoreKit2ObserverModeManagerDelegate
    /// for processing.
    func detectUnobservedTransactions(
        delegate: StoreKit2ObserverModeManagerDelegate?
    ) async {
        guard let mostRecentVerifiedTransaction: (
            verifiedTransaction: StoreKit.Transaction,
            jwsRepresentation: String
        ) = (await allTransactionsProvider.getAllTransactions()
            .compactMap { transaction in
                guard let verifiedTransaction = transaction.verifiedTransaction else {
                    return nil
                }
                return (
                    verifiedTransaction: verifiedTransaction,
                    jwsRepresentation: transaction.jwsRepresentation
                )
            }
            .sorted(by: { $0.verifiedTransaction.purchaseDate > $1.verifiedTransaction.purchaseDate })
            .first
        ) else {
            return
        }

        let transaction: StoreKit.Transaction = mostRecentVerifiedTransaction.verifiedTransaction
        let jwsRepresentation: String = mostRecentVerifiedTransaction.jwsRepresentation

        var cachedSyncedSK2ObserverModeTransactionIDs = Set(
            self.deviceCache.cachedSyncedSK2ObserverModeTransactionIDs(
                appUserID: currentUserProvider.currentAppUserID
            ) ?? []
        )

        guard !cachedSyncedSK2ObserverModeTransactionIDs.contains(transaction.id) else {
            return
        }

        do {
            try await delegate?.handleSK2ObserverModeTransaction(
                verifiedTransaction: transaction,
                jwsRepresentation: jwsRepresentation
            )

            cachedSyncedSK2ObserverModeTransactionIDs.insert(transaction.id)
            self.deviceCache.cachedSyncedSK2ObserverModeTransactionIDs(
                syncedSK2TransactionIDs: Array(cachedSyncedSK2ObserverModeTransactionIDs),
                appUserID: currentUserProvider.currentAppUserID
            )
        } catch {
            Logger.error(Strings.purchase.sk2_observer_mode_error_processing_transaction(error))
        }
    }
}

/// A wrapper protocol that allows for abstracting out calls to an `AsyncSequence<VerificationResult<Transaction>>`.
/// This will usually be `Transaction.all` in production but allows us to inject custom AsyncSequences for testing.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol AllTransactionsProviderType: Sendable {
    func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>]
}

/// A concretete implementation of `AllTransactionsProviderType` that fetches 
/// transactions from StoreKit's ``StoreKit/Transaction/all``
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class SK2AllTransactionsProvider: AllTransactionsProviderType, Sendable {
    func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>] {
        return await StoreKit.Transaction.all.extractValues()
    }
}
