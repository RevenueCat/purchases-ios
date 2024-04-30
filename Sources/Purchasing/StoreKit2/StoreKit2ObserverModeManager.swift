//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModeManager.swift
//
//  Created by Will Taylor on 4/30/24.

import Foundation
import StoreKit

/// A wrapper that allows managing observer-mode for StoreKit2, synchronized as an `actor`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol StoreKit2ObserverModeManagerType {

    /// Begins observing purchase transactions.
    func beginObservingPurchases() async

    /// Sets the delegate to handle observer mode transactions.
    /// - Parameter delegate: An object conforming to `StoreKit2ObserverModeManagerDelegate`
    /// that will handle the observed transactions.
    func set(delegate: StoreKit2ObserverModeManagerDelegate)

}

/// A delegate protocol for handling verified transactions in observer mode.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol StoreKit2ObserverModeManagerDelegate: AnyObject, Sendable {

    /// Handles a verified transaction with its corresponding JWS representation.
    /// - Parameters:
    ///   - verifiedTransaction: The verified transaction to be processed.
    ///   - jwsRepresentation: The JSON Web Signature representation of the transaction.
    func handleSK2ObserverModeTransaction(
        verifiedTransaction: StoreKit.Transaction,
        jwsRepresentation: String
    ) async throws
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StoreKit2ObserverModeManager: StoreKit2ObserverModeManagerType {

    private var delegate: StoreKit2ObserverModeManagerDelegate?
    private let notificationCenter: NotificationCenter
    private let storeKit2ObserverModePurchaseDetector: StoreKit2ObserverModePurchaseDetector

    /// Initializes a new manager with specified services and components.
    init(
        currentUserProvider: CurrentUserProvider,
        deviceCache: DeviceCache,
        notificationCenter: NotificationCenter
    ) {
        storeKit2ObserverModePurchaseDetector = StoreKit2ObserverModePurchaseDetector(
            deviceCache: deviceCache,
            currentUserProvider: currentUserProvider
        )
        self.notificationCenter = notificationCenter
    }

    func beginObservingPurchases() async {
        if let applicationDidBecomeActiveNotification = SystemInfo.applicationDidBecomeActiveNotification {
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: applicationDidBecomeActiveNotification,
                                           object: nil)
        }
    }

    @objc func applicationDidBecomeActive() {
        Task {
            await storeKit2ObserverModePurchaseDetector.detectUnobservedTransactions(delegate: self.delegate)
        }
    }

    func set(delegate: any StoreKit2ObserverModeManagerDelegate) {
        self.delegate = delegate
    }

    /// Actor responsibile for detecting purchases from StoreKit2 that should be processed by observer mode.
    actor StoreKit2ObserverModePurchaseDetector {

        private let deviceCache: DeviceCache
        private let currentUserProvider: CurrentUserProvider

        init(
            deviceCache: DeviceCache,
            currentUserProvider: CurrentUserProvider
        ) {
            self.deviceCache = deviceCache
            self.currentUserProvider = currentUserProvider
        }

        /// Detects unobserved transactions and forwards them to the StoreKit2ObserverModeManagerDelegate
        /// for processing.
        func detectUnobservedTransactions(
            delegate: StoreKit2ObserverModeManagerDelegate?
        ) async {
            guard let mostRecentVerifiedTransaction: (
                verifiedTransaction: StoreKit.Transaction,
                jwsRepresentation: String
            ) = (await StoreKit.Transaction.all.extractValues()
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

            // Try to avoid processing renewals since those will be picked up by
            // ``StoreKit2TransactionListener/listenForTransactions``.
            var purchaseOrLegacyOS = true
            if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, *) {
                purchaseOrLegacyOS = transaction.reason == .purchase
            }
            guard purchaseOrLegacyOS else { return }

            var cachedSyncedSK2TransactionIDs = Set(
                self.deviceCache.cachedSyncedSK2TransactionIDs(appUserID: currentUserProvider.currentAppUserID) ?? []
            )

            guard !cachedSyncedSK2TransactionIDs.contains(transaction.id) else {
                return
            }

            do {
                try await delegate?.handleSK2ObserverModeTransaction(
                    verifiedTransaction: transaction,
                    jwsRepresentation: jwsRepresentation
                )

                cachedSyncedSK2TransactionIDs.insert(mostRecentVerifiedTransaction.verifiedTransaction.id)
                self.deviceCache.cacheSyncedSK2TransactionIDs(
                    syncedSK2TransactionIDs: Array(cachedSyncedSK2TransactionIDs),
                    appUserID: currentUserProvider.currentAppUserID
                )
            } catch {
                Logger.error(Strings.purchase.sk2_observer_mode_error_processing_transaction(error))
            }
        }
    }
}
