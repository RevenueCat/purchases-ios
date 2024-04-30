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
    /// - Parameter delegate: An object conforming to `StoreKit2ObserverModeManagerDelegate` that will handle the observed transactions.
    func set(delegate: StoreKit2ObserverModeManagerDelegate) async

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

/// Manages observer mode operations for StoreKit 2 transactions.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
actor StoreKit2ObserverModeManager: StoreKit2ObserverModeManagerType {

    private var delegate: StoreKit2ObserverModeManagerDelegate?
    private let currentUserProvider: CurrentUserProvider
    private let deviceCache: DeviceCache
    private let notificationCenter: NotificationCenter
    private var applicationStateListener: ApplicationStateListener?

    /// Initializes a new manager with specified services and components.
    init(
        currentUserProvider: CurrentUserProvider,
        deviceCache: DeviceCache,
        notificationCenter: NotificationCenter
    ) {
        self.currentUserProvider = currentUserProvider
        self.deviceCache = deviceCache
        self.notificationCenter = notificationCenter
    }

    /// Listens for application state changes and notifies the parent manager to process transactions when the application becomes active.
    class ApplicationStateListener: Sendable {

        let onApplicationDidBecomeActive: (@Sendable () async -> Void)?
        let notificationCenter: NotificationCenter

        /// Initializes a new listener with optional completion handlers and a notification center.
        /// - Parameters:
        ///   - onApplicationDidBecomeActive: An optional asynchronous closure called when the app becomes active.
        ///   - notificationCenter: The notification center to listen for application state changes.
        init(
            notificationCenter: NotificationCenter,
            onApplicationDidBecomeActive: (@Sendable () async -> Void)?
        ) {
            self.onApplicationDidBecomeActive = onApplicationDidBecomeActive
            self.notificationCenter = notificationCenter
        }

        /// Begins listening for the application becoming active and triggers processing of transactions.
        func listenForApplicationDidBecomeActive() {
            if let applicationDidBecomeActiveNotification = SystemInfo.applicationDidBecomeActiveNotification {
                self.notificationCenter.addObserver(self,
                                                    selector: #selector(applicationDidBecomeActive),
                                                    name: applicationDidBecomeActiveNotification,
                                                    object: nil)
            }
        }

        /// Handles the event when the application becomes active by calling the associated handler.
        @objc func applicationDidBecomeActive() {
            Task { [weak self] in
                await self?.onApplicationDidBecomeActive?()
            }
        }
    }

    /// Sets a delegate to handle verified transactions.
    func set(delegate: any StoreKit2ObserverModeManagerDelegate) async {
        self.delegate = delegate
    }

    /// Begin listening for unobserved initial purchases, processing them when one is found.
    func beginObservingPurchases() {
        self.applicationStateListener = ApplicationStateListener(
            notificationCenter: notificationCenter,
            onApplicationDidBecomeActive: { [weak self] in
                await self?.processUnobservedTransactions()
            }
        )
        self.applicationStateListener?.listenForApplicationDidBecomeActive()
    }

    /// Processes unobserved transactions by checking the most recent verified transaction and updating the cache if necessary.
    private func processUnobservedTransactions() async {
        guard let mostRecentVerifiedTransaction = (await StoreKit.Transaction.all.extractValues()
            .compactMap { transaction -> (
                verifiedTransaction: StoreKit.Transaction, jwsRepresentation: String
            )? in
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

        // Try to avoid processing renewals since those will be picked up by
        // ``StoreKit2TransactionListener/listenForTransactions``.
        var purchaseOrLegacyOS = true
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            purchaseOrLegacyOS = mostRecentVerifiedTransaction.verifiedTransaction.reason == .purchase
        }
        guard purchaseOrLegacyOS else { return }

        var cachedSyncedSK2TransactionIDs = Set(
            self.deviceCache.cachedSyncedSK2TransactionIDs(appUserID: currentUserProvider.currentAppUserID) ?? []
        )

        guard !cachedSyncedSK2TransactionIDs.contains(mostRecentVerifiedTransaction.verifiedTransaction.id) else {
            return
        }

        do {
            try await self.delegate?.handleSK2ObserverModeTransaction(
                verifiedTransaction: mostRecentVerifiedTransaction.verifiedTransaction,
                jwsRepresentation: mostRecentVerifiedTransaction.jwsRepresentation
            )

            cachedSyncedSK2TransactionIDs.insert(mostRecentVerifiedTransaction.verifiedTransaction.id)
            self.deviceCache.cacheSyncedSK2TransactionIDs(syncedSK2TransactionIDs: Array(cachedSyncedSK2TransactionIDs),
                                                          appUserID: currentUserProvider.currentAppUserID)
        } catch {
            Logger.error(Strings.purchase.sk2_observer_mode_error_processing_transaction(error))
        }
    }
}
