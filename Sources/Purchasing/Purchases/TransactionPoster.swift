//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionPoster.swift
//
//  Created by Nacho Soto on 5/24/23.

import Foundation

// swiftlint:disable file_length

/// Determines what triggered a receipt to be posted and whether it comes from a restore.
struct PostReceiptSource: Equatable {

    /// Determines what triggered a receipt to be posted
    enum InitiationSource: CaseIterable {

        /// From a call to restore purchases
        case restore

        /// From a purchase
        case purchase

        /// From a transaction in the queue
        case queue

    }

    let isRestore: Bool
    let initiationSource: InitiationSource

}

/// Encapsulates data used when posting transactions to the backend.
struct PurchasedTransactionData {

    var presentedOfferingContext: PresentedOfferingContext?
    var presentedPaywall: PaywallEvent?
    var unsyncedAttributes: SubscriberAttribute.Dictionary?
    var metadata: [String: String]?
    var aadAttributionToken: String?
    var storeCountry: String?

}

/// Result of posting a single cached transaction metadata entry.
/// Contains the transaction data (for syncing attributes) and the result of the receipt post.
typealias CachedTransactionMetadataPostResult = (
    transactionData: PurchasedTransactionData,
    result: Result<CustomerInfo, BackendError>
)

/// A type that can post receipts as a result of a purchased transaction.
protocol TransactionPosterType: AnyObject, Sendable {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        postReceiptSource: PostReceiptSource,
        currentUserID: String,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    )

    /// Finishes the transaction if not in observer mode.
    /// - Note: `handlePurchasedTransaction` calls this automatically,
    /// this is only required for failed transactions.
    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    )

    // swiftlint:disable function_parameter_count
    func postReceiptFromSyncedSK2Transaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        receipt: EncodedAppleReceipt,
        postReceiptSource: PostReceiptSource,
        appTransactionJWS: String?,
        currentUserID: String,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    )

    /// Posts any remaining cached transaction metadata that wasn't synced during normal transaction processing.
    /// This handles edge cases where a transaction was cached but never successfully posted
    /// (e.g., due to app crashes or network issues).
    /// - Parameters:
    ///   - appUserID: The current app user ID to post the receipts for
    ///   - isRestore: Whether this is a restore operation
    /// - Returns: An `AsyncStream` that yields a result for each cached metadata entry as it's processed.
    ///           Each element contains the transaction data and the result of posting.
    ///           The stream completes after all entries have been processed.
    func postRemainingCachedTransactionMetadata(
        appUserID: String,
        isRestore: Bool
    ) -> AsyncStream<CachedTransactionMetadataPostResult>

}

final class TransactionPoster: TransactionPosterType {

    private let productsManager: ProductsManagerType
    private let receiptFetcher: ReceiptFetcher
    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let backend: Backend
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let operationDispatcher: OperationDispatcher
    private let localTransactionMetadataStore: LocalTransactionMetadataStoreType

    init(
        productsManager: ProductsManagerType,
        receiptFetcher: ReceiptFetcher,
        transactionFetcher: StoreKit2TransactionFetcherType,
        backend: Backend,
        paymentQueueWrapper: EitherPaymentQueueWrapper,
        systemInfo: SystemInfo,
        operationDispatcher: OperationDispatcher,
        localTransactionMetadataStore: LocalTransactionMetadataStoreType
    ) {
        self.productsManager = productsManager
        self.receiptFetcher = receiptFetcher
        self.transactionFetcher = transactionFetcher
        self.backend = backend
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.operationDispatcher = operationDispatcher
        self.localTransactionMetadataStore = localTransactionMetadataStore
    }

    func handlePurchasedTransaction(_ transaction: StoreTransactionType,
                                    data: PurchasedTransactionData,
                                    postReceiptSource: PostReceiptSource,
                                    currentUserID: String,
                                    completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        Logger.debug(Strings.purchase.transaction_poster_handling_transaction(
            transactionID: transaction.transactionIdentifier,
            productID: transaction.productIdentifier,
            transactionDate: transaction.purchaseDate,
            offeringID: data.presentedOfferingContext?.offeringIdentifier,
            placementID: data.presentedOfferingContext?.placementIdentifier,
            paywallSessionID: data.presentedPaywall?.data.sessionIdentifier
        ))

        guard let productIdentifier = transaction.productIdentifier.notEmpty else {
            self.finishTransactionIfNeededFromReceiptPost(transaction: transaction,
                                                          result: .failure(.missingTransactionProductIdentifier()),
                                                          completion: completion)
            return
        }

        self.fetchEncodedReceipt(transaction: transaction) { result in
            switch result {
            case .success(let encodedReceipt):
                self.product(with: productIdentifier) { product in
                    self.getAppTransactionJWSIfNeeded { appTransaction in
                        self.postReceipt(transaction: transaction,
                                         purchasedTransactionData: data,
                                         postReceiptSource: postReceiptSource,
                                         receipt: encodedReceipt,
                                         product: product,
                                         appTransaction: appTransaction,
                                         currentUserID: currentUserID) { result in
                            self.finishTransactionIfNeededFromReceiptPost(transaction: transaction,
                                                                          result: result.map { ($0, product) },
                                                                          completion: completion)
                        }
                    }
                }
            case .failure(let error):
                self.finishTransactionIfNeededFromReceiptPost(transaction: transaction,
                                                              result: .failure(error),
                                                              completion: completion)
            }
        }
    }

    // swiftlint:disable function_parameter_count
    func postReceiptFromSyncedSK2Transaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        receipt: EncodedAppleReceipt,
        postReceiptSource: PostReceiptSource,
        appTransactionJWS: String?,
        currentUserID: String,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        self.product(with: transaction.productIdentifier) { product in
            self.postReceipt(transaction: transaction,
                             purchasedTransactionData: data,
                             postReceiptSource: postReceiptSource,
                             receipt: receipt,
                             product: product,
                             appTransaction: appTransactionJWS,
                             currentUserID: currentUserID,
                             completion: completion)
        }
    }

    func postRemainingCachedTransactionMetadata(
        appUserID: String,
        isRestore: Bool
    ) -> AsyncStream<CachedTransactionMetadataPostResult> {
        return AsyncStream { continuation in
            let metadataToSync = self.localTransactionMetadataStore.getAllStoredMetadata()

            guard !metadataToSync.isEmpty else {
                continuation.finish()
                return
            }

            Logger.debug(Strings.purchase.posting_remaining_cached_metadata(count: metadataToSync.count))

            self.getAppTransactionJWSIfNeeded { appTransaction in
                self.postCachedMetadataSequentially(
                    metadataToSync: metadataToSync,
                    appUserID: appUserID,
                    isRestore: isRestore,
                    appTransaction: appTransaction,
                    continuation: continuation
                )
            }
        }
    }

    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        @Sendable
        func complete() {
            self.operationDispatcher.dispatchOnMainActor(completion)
        }

        guard self.finishTransactions else {
            complete()
            return
        }

        Logger.purchase(Strings.purchase.finishing_transaction(transaction))

        transaction.finish(self.paymentQueueWrapper.paymentQueueWrapperType, completion: complete)
    }

    static func shouldFinish(
        transaction: StoreTransactionType,
        for product: StoreProductType?,
        customerInfo: CustomerInfo
    ) -> Bool {
        // Don't finish transactions if CustomerInfo was computed offline
        guard !customerInfo.isComputedOffline else { return false }

        // If we couldn't find the product, we can't determine if it's a consumable
        guard let product = product else { return true }

        switch product.productCategory {
        case .subscription:
            // Note: this includes non-renewing subscriptions. Those are included in `.nonSubscriptions`,
            // but we can't tell them apart using `product.productType` because that's unknown for SK1 products.
            return true

        case .nonSubscription:
            // Only finish consumables if the server actually processed it.
            let shouldFinish = (
                !transaction.hasKnownTransactionIdentifier ||
                customerInfo.nonSubscriptions.contains {
                    $0.storeTransactionIdentifier == transaction.transactionIdentifier
                }
            )
            if !shouldFinish {
                Logger.warn(Strings.purchase.finish_transaction_skipped_because_its_missing_in_non_subscriptions(
                    transaction,
                    customerInfo.nonSubscriptions
                ))
            }

            return shouldFinish
        }
    }

}

/// Async extension
extension TransactionPosterType {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        data: PurchasedTransactionData,
        postReceiptSource: PostReceiptSource,
        currentUserID: String
    ) async -> Result<CustomerInfo, BackendError> {
        await Async.call { completion in
            self.handlePurchasedTransaction(
                transaction,
                data: data,
                postReceiptSource: postReceiptSource,
                currentUserID: currentUserID,
                completion: completion
            )
        }
    }

}

extension PostReceiptSource: Codable {}

// MARK: - Implementation

extension TransactionPoster {

    func finishTransactionIfNeededFromReceiptPost(
        transaction: StoreTransactionType,
        result: Result<
            (
                info: CustomerInfo,
                product: StoreProduct?
            ),
        BackendError
        >,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        let customerInfoResult = result.map(\.info)

        self.operationDispatcher.dispatchOnMainActor {
            switch result {
            case let .success((customerInfo, product)):
                if Self.shouldFinish(
                    transaction: transaction,
                    for: product,
                    customerInfo: customerInfo
                ) {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(customerInfoResult)
                    }
                } else {
                    completion(customerInfoResult)

                }

            case let .failure(error):
                if error.finishable {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(customerInfoResult)
                    }
                } else {
                    completion(customerInfoResult)
                }
            }
        }
    }

    // swiftlint:disable function_parameter_count function_body_length
    private func postReceipt(transaction: StoreTransactionType,
                             purchasedTransactionData: PurchasedTransactionData,
                             postReceiptSource: PostReceiptSource,
                             receipt: EncodedAppleReceipt,
                             product: StoreProduct?,
                             appTransaction: String?,
                             currentUserID: String,
                             completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let storedTransactionMetadata = self.localTransactionMetadataStore.getMetadata(
            forTransactionId: transaction.transactionIdentifier
        )
        let shouldStoreMetadata = storedTransactionMetadata == nil && (
            postReceiptSource.initiationSource == .purchase ||
            purchasedTransactionData.presentedOfferingContext != nil ||
            purchasedTransactionData.presentedPaywall != nil
        )

        let containsAttributionData = storedTransactionMetadata != nil || shouldStoreMetadata

        let effectiveProductData = storedTransactionMetadata?.productData ?? product.map {
            ProductRequestData(with: $0, storeCountry: purchasedTransactionData.storeCountry)
        }
        let effectiveTransactionData = storedTransactionMetadata?.transactionData ?? purchasedTransactionData
        let effectivePurchasesAreCompletedBy = storedTransactionMetadata?.originalPurchasesAreCompletedBy ??
        self.purchasesAreCompletedBy

        // sdkOriginated indicates whether this purchase was initiated by the SDK (stored metadata takes precedence):
        // - true when the purchase was initiated via SDK's purchase() methods (initiationSource == .purchase)
        // - false when the purchase was detected in the queue but triggered outside the SDK
        let sdkOriginated = storedTransactionMetadata?.sdkOriginated ??
            (postReceiptSource.initiationSource == .purchase)

        if shouldStoreMetadata {
            let metadataToStore = LocalTransactionMetadata(
                transactionId: transaction.transactionIdentifier,
                productData: effectiveProductData,
                transactionData: effectiveTransactionData,
                encodedAppleReceipt: receipt,
                originalPurchasesAreCompletedBy: effectivePurchasesAreCompletedBy,
                sdkOriginated: sdkOriginated
            )
            self.localTransactionMetadataStore.storeMetadata(metadataToStore,
                                                             forTransactionId: transaction.transactionIdentifier)
        }

        self.backend.post(receipt: receipt,
                          productData: effectiveProductData,
                          transactionData: effectiveTransactionData,
                          postReceiptSource: postReceiptSource,
                          observerMode: self.observerMode,
                          originalPurchaseCompletedBy: effectivePurchasesAreCompletedBy,
                          appTransaction: appTransaction,
                          associatedTransactionId: transaction.transactionIdentifier,
                          sdkOriginated: sdkOriginated,
                          appUserID: currentUserID,
                          containsAttributionData: containsAttributionData) { result in
            if containsAttributionData {
                switch result {
                case let .success(customerInfo) where !customerInfo.isComputedOffline:
                    // Offline-computed CustomerInfo means server is down, so it didn't process the transaction yet
                    self.localTransactionMetadataStore
                        .removeMetadata(forTransactionId: transaction.transactionIdentifier)
                case let .failure(error) where error.finishable:
                    self.localTransactionMetadataStore
                        .removeMetadata(forTransactionId: transaction.transactionIdentifier)
                default: break
                }
            }
            completion(result)
        }
    }

    func fetchEncodedReceipt(transaction: StoreTransactionType,
                             completion: @escaping (Result<EncodedAppleReceipt, BackendError>) -> Void) {
        if systemInfo.isSimulatedStoreAPIKey {
            let purchaseToken = transaction.jwsRepresentation ?? ""
            completion(.success(.jws(purchaseToken)))
            return
        }

        if systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable,
           let jwsRepresentation = transaction.jwsRepresentation {
            if transaction.environment == .xcode, #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                _ = Task<Void, Never> {
                    completion(.success(
                        .sk2receipt(await self.transactionFetcher.fetchReceipt(containing: transaction))
                    ))
                }
            } else {
                completion(.success(.jws(jwsRepresentation)))
            }
        } else {
            self.receiptFetcher.receiptData(
                refreshPolicy: self.refreshRequestPolicy(forProductIdentifier: transaction.productIdentifier)
            ) { receiptData, receiptURL in
                if let receiptData = receiptData, !receiptData.isEmpty {
                    completion(.success(.receipt(receiptData)))
                } else {
                    completion(.failure(BackendError.missingReceiptFile(receiptURL)))
                }
            }
        }
    }

    func getAppTransactionJWSIfNeeded(_ completion: @escaping (String?) -> Void) {
        if systemInfo.isSimulatedStoreAPIKey {
            completion(nil)
        } else {
            self.transactionFetcher.appTransactionJWS(completion)
        }
    }

}

// MARK: - Cached Metadata Posting

private extension TransactionPoster {

    /// Posts cached metadata entries sequentially, yielding each result to the continuation.
    func postCachedMetadataSequentially(
        metadataToSync: [LocalTransactionMetadata],
        appUserID: String,
        isRestore: Bool,
        appTransaction: String?,
        continuation: AsyncStream<CachedTransactionMetadataPostResult>.Continuation
    ) {
        var remainingMetadata = metadataToSync

        func postNext() {
            guard !remainingMetadata.isEmpty else {
                // All done
                continuation.finish()
                return
            }

            let metadata = remainingMetadata.removeFirst()

            self.postCachedMetadata(
                metadata: metadata,
                receipt: metadata.encodedAppleReceipt,
                appUserID: appUserID,
                isRestore: isRestore,
                appTransaction: appTransaction
            ) { transactionData, result in
                continuation.yield((transactionData, result))
                // Continue posting regardless of success or failure
                postNext()
            }
        }

        postNext()
    }

    /// Posts a single cached metadata entry.
    func postCachedMetadata(
        metadata: LocalTransactionMetadata,
        receipt: EncodedAppleReceipt,
        appUserID: String,
        isRestore: Bool,
        appTransaction: String?,
        completion: @escaping (PurchasedTransactionData, Result<CustomerInfo, BackendError>) -> Void
    ) {
        Logger.debug(Strings.purchase.posting_cached_metadata(transactionId: metadata.transactionId))

        let transactionData = metadata.transactionData
        // Set the source to indicate this is from unsynced purchases
        let postReceiptSource = PostReceiptSource(
            isRestore: isRestore,
            initiationSource: .queue
        )

        self.backend.post(
            receipt: receipt,
            productData: metadata.productData,
            transactionData: transactionData,
            postReceiptSource: postReceiptSource,
            observerMode: self.observerMode,
            originalPurchaseCompletedBy: metadata.originalPurchasesAreCompletedBy,
            appTransaction: appTransaction,
            associatedTransactionId: metadata.transactionId,
            appUserID: appUserID
        ) { result in
            // Clear metadata on success or finishable error
            switch result {
            case .success:
                self.localTransactionMetadataStore.removeMetadata(forTransactionId: metadata.transactionId)
            case let .failure(error) where error.finishable:
                self.localTransactionMetadataStore.removeMetadata(forTransactionId: metadata.transactionId)
            default:
                break
            }
            completion(transactionData, result)
        }
    }

}

// MARK: - Properties

private extension TransactionPoster {

    var observerMode: Bool {
        self.systemInfo.observerMode
    }

    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        return self.observerMode ? .myApp : .revenueCat
    }

    var finishTransactions: Bool {
        self.systemInfo.finishTransactions
    }

}

// MARK: - Receipt refreshing

extension TransactionPoster {

    private func refreshRequestPolicy(forProductIdentifier productIdentifier: String) -> ReceiptRefreshPolicy {
        if self.systemInfo.dangerousSettings.internalSettings.enableReceiptFetchRetry {
            return .retryUntilProductIsFound(productIdentifier: productIdentifier,
                                             maximumRetries: Self.receiptRetryCount,
                                             sleepDuration: Self.receiptRetrySleepDuration)
        } else {
            // See https://github.com/RevenueCat/purchases-ios/pull/2245 and
            // https://github.com/RevenueCat/purchases-ios/issues/2260
            // - Release or production builds:
            //      We don't _want_ to always refresh receipts to avoid throttling errors
            //      We don't _need_ to because the receipt will be refreshed by the backend using /verifyReceipt
            // - Debug and sandbox builds (potentially using StoreKit config files):
            //      We need to always refresh the receipt because the backend does not use /verifyReceipt
            //          when it was generated locally with SK config files.

            #if DEBUG
            return self.systemInfo.isSandbox
            ? .always
            : .onlyIfEmpty
            #else
            return .onlyIfEmpty
            #endif
        }
    }

    static let receiptRetryCount: Int = 3
    static let receiptRetrySleepDuration: DispatchTimeInterval = .seconds(5)

}

// MARK: - Products

private extension TransactionPoster {

    func product(with identifier: String, completion: @escaping (StoreProduct?) -> Void) {
        self.productsManager.products(withIdentifiers: [identifier]) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(products.value?.first)
            }
        }
    }

}
