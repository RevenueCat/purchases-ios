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
    var presentedOfferingContext: PresentedOfferingContext?
    var presentedPaywall: PaywallEvent?
    var unsyncedAttributes: SubscriberAttribute.Dictionary?
    var metadata: [String: String]?
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
    private let transactionFetcher: StoreKit2TransactionFetcherType
    private let backend: Backend
    private let paymentQueueWrapper: EitherPaymentQueueWrapper
    private let systemInfo: SystemInfo
    private let operationDispatcher: OperationDispatcher

    init(
        productsManager: ProductsManagerType,
        receiptFetcher: ReceiptFetcher,
        transactionFetcher: StoreKit2TransactionFetcherType,
        backend: Backend,
        paymentQueueWrapper: EitherPaymentQueueWrapper,
        systemInfo: SystemInfo,
        operationDispatcher: OperationDispatcher
    ) {
        self.productsManager = productsManager
        self.receiptFetcher = receiptFetcher
        self.transactionFetcher = transactionFetcher
        self.backend = backend
        self.paymentQueueWrapper = paymentQueueWrapper
        self.systemInfo = systemInfo
        self.operationDispatcher = operationDispatcher
    }

    func handlePurchasedTransaction(_ transaction: StoreTransactionType,
                                    data: PurchasedTransactionData,
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
            self.handleReceiptPost(withTransaction: transaction,
                                   result: .failure(.missingTransactionProductIdentifier()),
                                   subscriberAttributes: nil,
                                   completion: completion)
            return
        }

        self.fetchEncodedReceipt(transaction: transaction) { result in
            switch result {
            case .success(let encodedReceipt):
                self.product(with: productIdentifier) { product in
                    self.transactionFetcher.appTransactionJWS { appTransaction in
                        self.postReceipt(transaction: transaction,
                                         purchasedTransactionData: data,
                                         receipt: encodedReceipt,
                                         product: product,
                                         appTransaction: appTransaction,
                                         completion: completion)
                    }
                }
            case .failure(let error):
                self.handleReceiptPost(withTransaction: transaction,
                                       result: .failure(error),
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
        data: PurchasedTransactionData
    ) async -> Result<CustomerInfo, BackendError> {
        await Async.call { completion in
            self.handlePurchasedTransaction(transaction, data: data, completion: completion)
        }
    }

}

// MARK: - Implementation

private extension TransactionPoster {

    func handleReceiptPost(withTransaction transaction: StoreTransactionType,
                           result: Result<(info: CustomerInfo, product: StoreProduct?), BackendError>,
                           subscriberAttributes: SubscriberAttribute.Dictionary?,
                           completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
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

    // swiftlint:disable function_parameter_count
    func postReceipt(transaction: StoreTransactionType,
                     purchasedTransactionData: PurchasedTransactionData,
                     receipt: EncodedAppleReceipt,
                     product: StoreProduct?,
                     appTransaction: String?,
                     completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let productData = product.map { ProductRequestData(with: $0, storefront: purchasedTransactionData.storefront) }

        self.backend.post(receipt: receipt,
                          productData: productData,
                          transactionData: purchasedTransactionData,
                          observerMode: self.observerMode,
                          appTransaction: appTransaction) { result in
            self.handleReceiptPost(withTransaction: transaction,
                                   result: result.map { ($0, product) },
                                   subscriberAttributes: purchasedTransactionData.unsyncedAttributes,
                                   completion: completion)
        }
    }

    func fetchEncodedReceipt(transaction: StoreTransactionType,
                             completion: @escaping (Result<EncodedAppleReceipt, BackendError>) -> Void) {
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
