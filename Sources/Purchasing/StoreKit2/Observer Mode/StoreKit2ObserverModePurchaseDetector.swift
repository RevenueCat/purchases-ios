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

/// A delegate protocol for handling verified transactions in observer mode.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable type_name
protocol StoreKit2ObserverModePurchaseDetectorDelegate: AnyObject, Sendable {

    /// Handles a verified transaction with its corresponding JWS representation.
    /// - Parameters:
    ///   - verifiedTransaction: The verified transaction to be processed.
    ///   - jwsRepresentation: The JSON Web Signature representation of the transaction.
    func handleSK2ObserverModeTransaction(
        verifiedTransaction: StoreKit.Transaction,
        jwsRepresentation: String
    ) async throws
}

/// Protocol describing an actor capable of detecting purchases from StoreKit 2.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol StoreKit2ObserverModePurchaseDetectorType: Actor {
    func detectUnobservedTransactions(
        delegate: StoreKit2ObserverModePurchaseDetectorDelegate
    ) async
}

/// Actor responsibile for detecting purchases from StoreKit2 that should be processed by observer mode.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
actor StoreKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetectorType {

    private let deviceCache: DeviceCache
    private let allTransactionsProvider: AllTransactionsProviderType

    init(
        deviceCache: DeviceCache,
        allTransactionsProvider: AllTransactionsProviderType
    ) {
        self.deviceCache = deviceCache
        self.allTransactionsProvider = allTransactionsProvider
    }

    /// Detects unobserved transactions and forwards them to the StoreKit2ObserverModeManagerDelegate
    /// for processing.
    func detectUnobservedTransactions(
        delegate: StoreKit2ObserverModePurchaseDetectorDelegate
    ) async {

        let allTransactions = await allTransactionsProvider.getAllTransactions()

        guard let mostRecentTransaction = await allTransactionsProvider.getMostRecentVerifiedTransaction(
            from: allTransactions
        ) else { return }

        let jwsRepresentation = mostRecentTransaction.jwsRepresentation
        guard let transaction = mostRecentTransaction.verifiedTransaction else { return }

        let cachedSyncedSK2ObserverModeTransactionIDs = Set(
            self.deviceCache.cachedSyncedSK2ObserverModeTransactionIDs()
        )
        if cachedSyncedSK2ObserverModeTransactionIDs.contains(transaction.id) { return }

        let unsyncedTransactionIDs = allTransactions
            .filter {
                !cachedSyncedSK2ObserverModeTransactionIDs.contains($0.underlyingTransaction.id)
            }
            .map { $0.underlyingTransaction.id }

        do {
            try await delegate.handleSK2ObserverModeTransaction(
                verifiedTransaction: transaction,
                jwsRepresentation: jwsRepresentation
            )

            deviceCache.registerNewSyncedSK2ObserverModeTransactionIDs(unsyncedTransactionIDs)
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
    func getMostRecentVerifiedTransaction(
        from transactions: [StoreKit.VerificationResult<StoreKit.Transaction>]
    ) async -> StoreKit.VerificationResult<StoreKit.Transaction>?
}

/// A concretete implementation of `AllTransactionsProviderType` that fetches 
/// transactions from StoreKit's ``StoreKit/Transaction/all``
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SK2AllTransactionsProvider: AllTransactionsProviderType, Sendable {
    func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>] {
        return await StoreKit.Transaction.all.extractValues()
    }

    func getMostRecentVerifiedTransaction(
        from transactions: [StoreKit.VerificationResult<StoreKit.Transaction>]
    ) async -> StoreKit.VerificationResult<StoreKit.Transaction>? {
        let verifiedTransactions = transactions.filter { transaction in
            return transaction.verifiedTransaction != nil
        }
        if verifiedTransactions.isEmpty { return nil }
        guard let mostRecentTransaction = verifiedTransactions.max(by: {
            $0.verifiedTransaction?.purchaseDate ?? .distantPast < $1.verifiedTransaction?.purchaseDate ?? .distantPast
        }) else { return nil }

        return mostRecentTransaction
    }
}
