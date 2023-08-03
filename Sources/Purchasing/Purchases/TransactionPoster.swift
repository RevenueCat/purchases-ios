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

/// A type that can post receipts as a result of a purchased transaction.
protocol TransactionPosterType: AnyObject, Sendable {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    )

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
    private let purchasedProductsFetcher: PurchasedProductsFetcherType?
    private let backend: Backend
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let operationDispatcher: OperationDispatcher

    init(
        productsManager: ProductsManagerType,
        receiptFetcher: ReceiptFetcher,
        purchasedProductsFetcher: PurchasedProductsFetcherType?,
        backend: Backend,
        paymentQueueWrapper: EitherPaymentQueueWrapper,
        systemInfo: SystemInfo,
        operationDispatcher: OperationDispatcher
    ) {
        self.productsManager = productsManager
        self.receiptFetcher = receiptFetcher
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.backend = backend
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.operationDispatcher = operationDispatcher
    }

    func handlePurchasedTransaction(_ transaction: StoreTransactionType,
                                    data: PurchasedTransactionData,
                                    completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        Logger.debug(Strings.purchase.transaction_poster_handling_transaction(
            productID: transaction.productIdentifier,
            offeringID: data.presentedOfferingID
        ))

        self.purchasedProductsFetcher?.fetchPurchasedProductForTransaction(
          transaction.transactionIdentifier
        ) { jwsRepresentation in
          guard let jwsRepresentation = jwsRepresentation else {
            fatalError("Could not fetch jswRepesentation")
          }
          self.fetchProductsAndPostReceipt(
              transaction: transaction,
              data: data,
              receiptData: jwsRepresentation.asData,
              completion: completion
          )
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

}

/// Async extension
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension TransactionPosterType {

    /// Starts a `PostReceiptDataOperation` for the transaction.
    func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        data: PurchasedTransactionData
    ) async -> Result<CustomerInfo, BackendError> {
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
            self.product(with: productIdentifier) { products in
                self.postReceipt(transaction: transaction,
                                 purchasedTransactionData: data,
                                 receiptData: receiptData,
                                 product: products,
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
                           result: Result<CustomerInfo, BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary?,
                           completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        self.operationDispatcher.dispatchOnMainActor {
            switch result {
            case let .success(customerInfo):
                if customerInfo.isComputedOffline {
                    completion(result)
                } else {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(result)
                    }
                }

            case let .failure(error):
                if error.finishable {
                    self.finishTransactionIfNeeded(transaction) {
                        completion(result)
                    }
                } else {
                    completion(result)
                }
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
                                   result: result,
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
