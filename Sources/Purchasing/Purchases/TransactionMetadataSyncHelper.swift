//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionMetadataSyncHelper.swift
//
//  Created by RevenueCat.

import Foundation

/// Helper class responsible for syncing remaining cached transaction metadata
/// that wasn't synced during normal transaction processing.
/// This handles edge cases where a transaction is not returned by the store anymore
/// but we still have metadata cached for it.
final class TransactionMetadataSyncHelper {

    private let customerInfoManager: CustomerInfoManager
    private let attribution: Attribution
    private let currentUserProvider: CurrentUserProvider
    private let operationDispatcher: OperationDispatcher
    private let transactionPoster: TransactionPosterType

    private let isSyncing: Atomic<Bool> = .init(false)

    private var appUserID: String { self.currentUserProvider.currentAppUserID }

    init(
        customerInfoManager: CustomerInfoManager,
        attribution: Attribution,
        currentUserProvider: CurrentUserProvider,
        operationDispatcher: OperationDispatcher,
        transactionPoster: TransactionPosterType
    ) {
        self.customerInfoManager = customerInfoManager
        self.attribution = attribution
        self.currentUserProvider = currentUserProvider
        self.operationDispatcher = operationDispatcher
        self.transactionPoster = transactionPoster
    }

    /// Posts any remaining cached transaction metadata that wasn't synced during normal transaction processing.
    /// This handles edge cases where a transaction is not returned by the store anymore but we still have
    /// metadata cached for it.
    func syncIfNeeded(allowSharingAppStoreAccount: Bool) {
        #if DEBUG
        let delay: JitterableDelay = ProcessInfo.isRunningRevenueCatTests ? .none : .default
        #else
        let delay: JitterableDelay = .default
        #endif
        self.operationDispatcher.dispatchOnWorkerThread(jitterableDelay: delay) {
            Task {
                await self.performSync(allowSharingAppStoreAccount: allowSharingAppStoreAccount)
            }
        }
    }

    func performSync(allowSharingAppStoreAccount: Bool) async {
        guard self.isSyncing.getAndSet(true) == false else {
            Logger.debug(Strings.purchase.cached_transaction_metadata_sync_already_in_progress)
            return
        }
        defer { self.isSyncing.value = false }

        let currentAppUserID = self.appUserID
        let isRestore = allowSharingAppStoreAccount

        let resultsStream = self.transactionPoster.postRemainingCachedTransactionMetadata(
            appUserID: currentAppUserID,
            isRestore: isRestore
        )

        for await (transactionData, result) in resultsStream {
            if let customerInfo = try? result.get() {
                self.customerInfoManager.cache(customerInfo: customerInfo, appUserID: currentAppUserID)
            }
            self.attribution.markSyncedIfNeeded(
                subscriberAttributes: transactionData.unsyncedAttributes,
                adServicesToken: transactionData.aadAttributionToken,
                appUserID: currentAppUserID,
                error: result.error
            )
        }

        Logger.debug(Strings.purchase.finished_posting_cached_metadata)
    }

}

extension TransactionMetadataSyncHelper: Sendable {}
