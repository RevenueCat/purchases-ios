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

/// Determines what triggered a purchase and whether it comes from a restore.
struct PurchaseSource: Equatable {

    let isRestore: Bool
    let initiationSource: ProductRequestData.InitiationSource

}

/// Encapsulates data used when posting transactions to the backend.
struct PurchasedTransactionData {

    var appUserID: String
    var presentedOfferingID: String?
    var unsyncedAttributes: SubscriberAttribute.Dictionary?
    var aadAttributionToken: String?
    var storefront: StorefrontType?
    var source: PurchaseSource

}

/// The possible results when posting a transaction.
enum TransactionPosterResult {

    /// Transaction was handled and backend returned a `CustomerInfo`
    /// or it was computed offline.
    case success(CustomerInfo)

    /// Transaction had already been posted.
    case alreadyPosted

    /// Error posting transaction.
    case failure(BackendError)

    init(_ result: Swift.Result<CustomerInfo, BackendError>) {
        switch result {
        case let .success(customerInfo):
            self = .success(customerInfo)
        case let .failure(error):
            self = .failure(error)
        }
    }

    var customerInfo: CustomerInfo? {
        switch self {
        case let .success(customerInfo):
            return customerInfo
        case .alreadyPosted, .failure:
            return nil
        }
    }

    var error: BackendError? {
        switch self {
        case let .failure(error):
            return error
        case .success, .alreadyPosted:
            return nil
        }
    }

}

/// A type that can post receipts as a result of a purchased transaction.
protocol TransactionPosterType: AnyObject, Sendable {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        completion: @escaping (TransactionPosterResult) -> Void
    )

    /// - Returns: the subset of `transactions` that have not been posted.
    func unpostedTransactions<T: StoreTransactionType>(in transactions: [T]) -> [T]

    /// Finishes the transaction if not in observer mode.
    /// - Note: `handlePurchasedTransaction` calls this automatically,
    /// this is only required for failed transactions.
    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    )

}

final class TransactionPoster: TransactionPosterType {

    private let productsManager: ProductsManagerType
    private let receiptFetcher: ReceiptFetcher
    private let backend: Backend
    private let cache: PostedTransactionCacheType
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let operationDispatcher: OperationDispatcher

    init(
        productsManager: ProductsManagerType,
        receiptFetcher: ReceiptFetcher,
        backend: Backend,
        cache: PostedTransactionCacheType,
        paymentQueueWrapper: EitherPaymentQueueWrapper,
        systemInfo: SystemInfo,
        operationDispatcher: OperationDispatcher
    ) {
        self.productsManager = productsManager
        self.receiptFetcher = receiptFetcher
        self.backend = backend
        self.cache = cache
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.operationDispatcher = operationDispatcher
    }

    func handlePurchasedTransaction(_ transaction: StoreTransactionType,
                                    data: PurchasedTransactionData,
                                    completion: @escaping (TransactionPosterResult) -> Void) {
        Logger.debug(Strings.purchase.transaction_poster_handling_transaction(
            productID: transaction.productIdentifier,
            offeringID: data.presentedOfferingID
        ))

        guard !self.cache.hasPostedTransaction(transaction) else {
            Logger.debug(Strings.purchase.transaction_poster_skipping_duplicate(
                productID: transaction.productIdentifier,
                transactionID: transaction.transactionIdentifier
            ))

            self.finishTransactionIfNeeded(transaction) {
                completion(.alreadyPosted)
            }

            return
        }

        self.receiptFetcher.receiptData(
            refreshPolicy: self.refreshRequestPolicy(forProductIdentifier: transaction.productIdentifier)
        ) { receiptData, receiptURL in
            if let receiptData = receiptData, !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(
                    transaction: transaction,
                    data: data,
                    receiptData: receiptData
                ) {
                    completion(.init($0))
                }
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       result: .failure(.missingReceiptFile(receiptURL)),
                                       subscriberAttributes: nil) {
                    completion(.init($0))
                }
            }
        }
    }

    func unpostedTransactions<T: StoreTransactionType>(in transactions: [T]) -> [T] {
        return self.cache.unpostedTransactions(in: transactions)
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

// MARK: - Extensions

extension TransactionPosterResult {

    typealias CustomerInfoFetcher = (@escaping @Sendable (Result<CustomerInfo, BackendError>) -> Void) -> Void

    /// Converts the `TransactionPosterResult` into `Result<CustomerInfo, BackendError>`
    /// by using `customerInfoFetcher` if the result is `.alreadyPosted`.
    func toResult(
        completion: @escaping @Sendable (Result<CustomerInfo, BackendError>) -> Void,
        customerInfoFetcher: CustomerInfoFetcher
    ) {
        switch self {
        case let .success(customerInfo):
            completion(.success(customerInfo))
        case .alreadyPosted:
            customerInfoFetcher { result in
                completion(result)
            }
        case let .failure(error):
            completion(.failure(error))
        }
    }

}

// MARK: - Async extensions

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension TransactionPosterType {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        data: PurchasedTransactionData
    ) async -> TransactionPosterResult {
        await Async.call { completion in
            self.handlePurchasedTransaction(transaction, data: data, completion: completion)
        }
    }

}

// MARK: - Implementation

private extension TransactionPoster {

    func fetchProductsAndPostReceipt(
        transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        receiptData: Data,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        if let productIdentifier = transaction.productIdentifier.notEmpty {
            self.product(with: productIdentifier) { product in
                self.postReceipt(transaction: transaction,
                                 purchasedTransactionData: data,
                                 receiptData: receiptData,
                                 product: product,
                                 completion: completion)
            }
        } else {
            self.handleReceiptPost(withTransaction: transaction,
                                   result: .failure(.missingTransactionProductIdentifier()),
                                   subscriberAttributes: nil,
                                   completion: completion)
        }
    }

    func handleReceiptPost(withTransaction transaction: StoreTransactionType,
                           result: Result<(info: CustomerInfo, product: StoreProduct?), BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary?,
                           completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let complete: @Sendable () -> Void = {
            self.operationDispatcher.dispatchOnMainActor {
                completion(result.map(\.info))
            }
        }

        switch result {
        case let .success((customerInfo, product)):
            self.cache.savePostedTransaction(transaction)

            if Self.shouldFinish(
                transaction: transaction,
                for: product,
                customerInfo: customerInfo
            ) {
                self.finishTransactionIfNeeded(transaction) {
                    Logger.debug(Strings.purchase.transaction_poster_storing_posted_transaction(
                        productID: transaction.productIdentifier,
                        transactionID: transaction.transactionIdentifier
                    ))

                    complete()
                }
            } else {
                complete()
            }

        case let .failure(error):
            if error.finishable {
                self.cache.savePostedTransaction(transaction)
                self.finishTransactionIfNeeded(transaction, completion: complete)
            } else {
                complete()
            }
        }
    }

    func postReceipt(transaction: StoreTransactionType,
                     purchasedTransactionData: PurchasedTransactionData,
                     receiptData: Data,
                     product: StoreProduct?,
                     completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let productData = product.map { ProductRequestData(with: $0, storefront: purchasedTransactionData.storefront) }

        self.backend.post(receiptData: receiptData,
                          productData: productData,
                          transactionData: purchasedTransactionData,
                          observerMode: self.observerMode) { result in
            self.handleReceiptPost(withTransaction: transaction,
                                   result: result.map { ($0, product) },
                                   subscriberAttributes: purchasedTransactionData.unsyncedAttributes,
                                   completion: completion)
        }
    }

}

// MARK: - Properties

private extension TransactionPoster {

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
