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

/// Determines what triggered a purchase and whether it comes from a restore.
struct PurchaseSource {

    let isRestore: Bool
    let initiationSource: ProductRequestData.InitiationSource

}

/// A type that can post receipts as a result of a purchased transaction.
protocol TransactionPosterType: AnyObject, Sendable {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        presentedOfferingID: String?,
        storefront: StorefrontType?,
        source: PurchaseSource,
        completion: @escaping PurchaseCompletedBlock
    )

    /// Finishes the transaction if not in observer mode.
    /// - Note: `handlePurchasedTransaction` calls this automatically,
    /// this is only required for failed transactions.
    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    )

    func markSyncedIfNeeded(
        subscriberAttributes: SubscriberAttribute.Dictionary?,
        error: BackendError?
    )

}

// swiftlint:disable function_parameter_count

final class TransactionPoster: TransactionPosterType {

    private let productsManager: ProductsManagerType
    private let receiptFetcher: ReceiptFetcher
    private let currentUserProvider: CurrentUserProvider
    private let attribution: Attribution
    private let backend: Backend
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let operationDispatcher: OperationDispatcher

    init(
        productsManager: ProductsManagerType,
        receiptFetcher: ReceiptFetcher,
        currentUserProvider: CurrentUserProvider,
        attribution: Attribution,
        backend: Backend,
        paymentQueueWrapper: EitherPaymentQueueWrapper,
        systemInfo: SystemInfo,
        operationDispatcher: OperationDispatcher
    ) {
        self.productsManager = productsManager
        self.receiptFetcher = receiptFetcher
        self.currentUserProvider = currentUserProvider
        self.attribution = attribution
        self.backend = backend
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.operationDispatcher = operationDispatcher
    }

    func handlePurchasedTransaction(_ transaction: StoreTransaction,
                                    presentedOfferingID: String?,
                                    storefront: StorefrontType?,
                                    source: PurchaseSource,
                                    completion: @escaping PurchaseCompletedBlock) {
        self.receiptFetcher.receiptData(
            refreshPolicy: self.refreshRequestPolicy(forProductIdentifier: transaction.productIdentifier)
        ) { receiptData in
            if let receiptData = receiptData, !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(
                    withTransaction: transaction,
                    receiptData: receiptData,
                    source: source,
                    storefront: storefront,
                    presentedOfferingID: presentedOfferingID,
                    completion: completion
                )
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       result: .failure(.missingReceiptFile()),
                                       subscriberAttributes: nil,
                                       completion: completion)
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

    func markSyncedIfNeeded(
        subscriberAttributes: SubscriberAttribute.Dictionary?,
        error: BackendError?
    ) {
        if let error = error {
            guard error.successfullySynced else { return }

            if let attributeErrors = (error as NSError).subscriberAttributesErrors, !attributeErrors.isEmpty {
                Logger.error(Strings.attribution.subscriber_attributes_error(
                    errors: attributeErrors
                ))
            }
        }

        self.attribution.markAttributesAsSynced(subscriberAttributes, appUserID: self.appUserID)
    }

}

// MARK: - Implementation

private extension TransactionPoster {

    /// Called as a result a purchase.
    func fetchProductsAndPostReceipt(
        withTransaction transaction: StoreTransaction,
        receiptData: Data,
        source: PurchaseSource,
        storefront: StorefrontType?,
        presentedOfferingID: String?,
        completion: @escaping PurchaseCompletedBlock
    ) {
        if let productIdentifier = transaction.productIdentifier.notEmpty {
            self.product(with: productIdentifier) { products in
                self.postReceipt(withTransaction: transaction,
                                 receiptData: receiptData,
                                 product: products,
                                 source: source,
                                 storefront: storefront,
                                 presentedOfferingID: presentedOfferingID,
                                 completion: completion)
            }
        } else {
            self.handleReceiptPost(withTransaction: transaction,
                                   result: .failure(.missingTransactionProductIdentifier()),
                                   subscriberAttributes: nil,
                                   completion: completion)
        }
    }

    func handleReceiptPost(withTransaction transaction: StoreTransaction,
                           result: Result<CustomerInfo, BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary?,
                           completion: @escaping PurchaseCompletedBlock) {
        self.operationDispatcher.dispatchOnMainActor {
            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    error: result.error)

            switch result {
            case let .success(customerInfo):
                if customerInfo.isComputedOffline {
                    completion(transaction, customerInfo, nil, false)
                } else {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(transaction, customerInfo, nil, false)
                    }
                }

            case let .failure(error):
                let publicError = error.asPublicError

                if error.finishable {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(transaction, nil, publicError, false)
                    }
                } else {
                    completion(transaction, nil, publicError, false)
                }
            }
        }
    }

    func postReceipt(withTransaction transaction: StoreTransaction,
                     receiptData: Data,
                     product: StoreProduct?,
                     source: PurchaseSource,
                     storefront: StorefrontType?,
                     presentedOfferingID: String?,
                     completion: @escaping PurchaseCompletedBlock) {
        let productData = product.map { ProductRequestData(with: $0, storefront: storefront) }
        let unsyncedAttributes = self.unsyncedAttributes

        self.backend.post(receiptData: receiptData,
                          appUserID: self.appUserID,
                          isRestore: source.isRestore,
                          productData: productData,
                          presentedOfferingIdentifier: presentedOfferingID,
                          observerMode: self.observerMode,
                          initiationSource: source.initiationSource,
                          subscriberAttributes: unsyncedAttributes) { result in
            self.handleReceiptPost(withTransaction: transaction,
                                   result: result,
                                   subscriberAttributes: unsyncedAttributes,
                                   completion: completion)
        }
    }

}

// MARK: - Properties

private extension TransactionPoster {

    private var appUserID: String {
        self.currentUserProvider.currentAppUserID
    }

    var unsyncedAttributes: SubscriberAttribute.Dictionary {
        self.attribution.unsyncedAttributesByKey(appUserID: self.appUserID)
    }

    var observerMode: Bool {
        self.systemInfo.observerMode
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
