//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionPosterTests.swift
//
//  Created by Nacho Soto on 5/26/23.

import Nimble
import XCTest

@testable import RevenueCat

class TransactionPosterTests: TestCase {

    private var productsManager: MockProductsManager!
    private var receiptFetcher: MockReceiptFetcher!
    private var backend: MockBackend!
    private var cache: MockPostedTransactionCache!
    private var paymentQueueWrapper: MockPaymentQueueWrapper!
    private var systemInfo: MockSystemInfo!
    private var operationDispatcher: MockOperationDispatcher!

    private var poster: TransactionPoster!

    private var mockTransaction: MockStoreTransaction!

    private static let mockCustomerInfo: CustomerInfo = .emptyInfo

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setUp(observerMode: false)
        self.mockTransaction = .init()
    }

    func testHandlePurchasedTransactionWithMissingReceipt() throws {
        self.receiptFetcher.mockReceiptURL = URL(string: "file://receipt_file")!
        self.receiptFetcher.shouldReturnReceipt = false

        let result = try self.handleTransaction(
            .init(
                appUserID: "user",
                source: .init(isRestore: false, initiationSource: .queue)
            )
        )
        expect(result.error) == BackendError.missingReceiptFile(self.receiptFetcher.mockReceiptURL)
        expect(result.error?.finishable) == false

        expect(self.cache.postedTransactions).to(beEmpty())
    }

    func testHandlePurchasedTransactionWithFinishableErrorSavesPostedTransaction() throws {
        self.receiptFetcher.shouldReturnReceipt = true
        self.backend.stubbedPostReceiptResult = .failure(
            .networkError(.errorResponse(.defaultResponse, .invalidRequest))
        )

        let result = try self.handleTransaction(
            .init(
                appUserID: "user",
                source: .init(isRestore: false, initiationSource: .queue)
            )
        )
        expect(result.error?.finishable) == true

        self.verifyTransactionWasCached()
    }

    func testHandlePurchasedTransaction() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result.customerInfo) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true

        self.verifyTransactionWasCached()
    }

    func testHandlePurchasedTransactionDoesNotPostItTwice() throws {
        self.cache.savePostedTransaction(self.mockTransaction)

        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        let result = try self.handleTransaction(transactionData)
        expect(result.wasAlreadyPosted) == true

        expect(self.backend.invokedPostReceiptData) == false
        expect(self.mockTransaction.finishInvoked) == true

        self.logger.verifyMessageWasLogged(
            Strings.purchase.transaction_poster_skipping_duplicate(
                productID: self.mockTransaction.productIdentifier,
                transactionID: self.mockTransaction.transactionIdentifier
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testHandlePurchasedTransactionMultipleTimesPostsItOnce() throws {
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )
        let count = 10

        self.backend.stubbedPostReceiptResult = .success(self.createCustomerInfo(nonSubscriptionProductID: nil))

        for _ in 0..<count {
            _ = try self.handleTransaction(transactionData)
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.mockTransaction.finishInvokedCount) == count

        expect(self.cache.postedTransactions) == [self.mockTransaction.transactionIdentifier]
    }

    func testHandlePurchasedTransactionDoesNotFinishNonProcessedConsumables() throws {
        let product = Self.createTestProduct(.consumable)
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )
        let customerInfo = self.createCustomerInfo(nonSubscriptionProductID: nil)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([product.toStoreProduct()])
        self.backend.stubbedPostReceiptResult = .success(customerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result.customerInfo) === customerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == false

        self.verifyTransactionWasCached()

        self.logger.verifyMessageWasLogged(
            Strings.purchase.finish_transaction_skipped_because_its_missing_in_non_subscriptions(
                self.mockTransaction,
                customerInfo.nonSubscriptions
            ),
            level: .warn,
            expectedCount: 1
        )
    }

    func testHandlePurchasedTransactionFinishesProcessedConsumable() throws {
        let product = Self.createTestProduct(.consumable)
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )
        let customerInfo = self.createCustomerInfo(nonSubscriptionProductID: product.productIdentifier)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([product.toStoreProduct()])
        self.backend.stubbedPostReceiptResult = .success(customerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result.customerInfo) === customerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true

        self.verifyTransactionWasCached()
    }

    func testHandlePurchasedTransactionDoesNotFinishTransactionInObserverMode() throws {
        self.setUp(observerMode: true)

        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result.customerInfo) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == true
        expect(self.mockTransaction.finishInvoked) == false

        self.verifyTransactionWasCached()
    }

    // MARK: - finishTransactionIfNeeded

    func testFinishTransactionInObserverMode() throws {
        waitUntil { completed in
            self.poster.finishTransactionIfNeeded(self.mockTransaction) {
                completed()
            }
        }

        self.logger.verifyMessageWasLogged(Strings.purchase.finishing_transaction(self.mockTransaction))
    }

    func testFinishTransactionDoesNotFinishInObserverMode() throws {
        self.setUp(observerMode: true)

        waitUntil { completed in
            self.poster.finishTransactionIfNeeded(self.mockTransaction) {
                completed()
            }
        }

        self.logger.verifyMessageWasNotLogged("Finished transaction")
    }

    // MARK: - shouldFinishTransaction

    func testShouldNotFinishWithOfflineCustomerInfo() throws {
        // Offline CustomerInfo isn't available on iOS 12
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let info = Self.mockCustomerInfo.copy(with: .verifiedOnDevice)

        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: nil,
                customerInfo: info)
        ) == false
    }

    func testShouldFinishTransactionWithMissingProduct() {
        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: nil,
                customerInfo: Self.mockCustomerInfo)
        ) == true
    }

    func testShouldFinishAutoRenewableSubscription() {
        let mockProduct = Self.createTestProduct(.autoRenewableSubscription)
        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: mockProduct,
                customerInfo: Self.mockCustomerInfo)
        ) == true
    }

    func testShouldFinishNonRenewableSubscription() {
        let mockProduct = Self.createTestProduct(.nonRenewableSubscription)
        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: mockProduct,
                customerInfo: Self.mockCustomerInfo)
        ) == true
    }

    func testShouldFinishConsumableIncludedInNonSubscriptions() throws {
        let product = Self.createTestProduct(.consumable)
        let customerInfo = self.createCustomerInfo(nonSubscriptionProductID: product.productIdentifier)

        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: product.toStoreProduct(),
                customerInfo: customerInfo)
        ) == true
    }

    func testShouldNotFinishConsumableNotIncludedInNonSubscriptions() throws {
        let product = Self.createTestProduct(.consumable)
        let customerInfo = self.createCustomerInfo(nonSubscriptionProductID: nil)

        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: product.toStoreProduct(),
                customerInfo: customerInfo)
        ) == false
    }

    func testShouldFinishTransactionWithUnknownIdentifier() throws {
        let product = Self.createTestProduct(.consumable)
        let customerInfo = self.createCustomerInfo(nonSubscriptionProductID: nil)

        self.mockTransaction.hasKnownTransactionIdentifier = false

        expect(
            TransactionPoster.shouldFinish(
                transaction: self.mockTransaction,
                for: product.toStoreProduct(),
                customerInfo: customerInfo)
        ) == true
    }

}

// MARK: -

private extension TransactionPosterTests {

    func setUp(observerMode: Bool) {
        self.operationDispatcher = .init()
        self.systemInfo = .init(finishTransactions: !observerMode)
        self.productsManager = .init(systemInfo: self.systemInfo, requestTimeout: 0)
        self.receiptFetcher = .init(requestFetcher: .init(operationDispatcher: self.operationDispatcher),
                                    systemInfo: self.systemInfo)
        self.backend = .init()
        self.cache = .init()
        self.paymentQueueWrapper = .init()

        self.poster = .init(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            backend: self.backend,
            cache: self.cache,
            paymentQueueWrapper: .right(self.paymentQueueWrapper),
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher
        )
    }

    func handleTransaction(_ data: PurchasedTransactionData) throws -> TransactionPosterResult {
        let result = waitUntilValue { completion in
            self.poster.handlePurchasedTransaction(self.mockTransaction, data: data) {
                completion($0)
            }
        }

        return try XCTUnwrap(result)
    }

    static func createTestProduct(_ productType: StoreProduct.ProductType) -> TestStoreProduct {
        return .init(localizedTitle: "Title",
                     price: 1.99,
                     localizedPriceString: "$1.99",
                     productIdentifier: "product",
                     productType: productType,
                     localizedDescription: "Description")
    }

    func createCustomerInfo(nonSubscriptionProductID: String?) -> CustomerInfo {
        let nonSubscriptions: [String: [CustomerInfoResponse.Transaction]]

        if let productID = nonSubscriptionProductID {
            nonSubscriptions = [
                productID: [
                    CustomerInfoResponse.Transaction(
                        purchaseDate: Date(),
                        originalPurchaseDate: Date(),
                        transactionIdentifier: UUID().uuidString,
                        storeTransactionIdentifier: self.mockTransaction.transactionIdentifier,
                        store: .appStore,
                        isSandbox: true
                    )
                ]
            ]
        } else {
            nonSubscriptions = [:]
        }

        let response = CustomerInfoResponse(
            subscriber: .init(
                originalAppUserId: "user",
                firstSeen: Date(),
                subscriptions: [:],
                nonSubscriptions: nonSubscriptions,
                entitlements: [:]
            ),
            requestDate: Date(),
            rawData: [:]
        )
        return CustomerInfo(response: response,
                            entitlementVerification: .notRequested,
                            sandboxEnvironmentDetector: self.systemInfo)
    }

    func verifyTransactionWasCached(file: FileString = #file, line: UInt = #line) {
        expect(
            file: file, line: line,
            self.cache.postedTransactions
        ).to(
            contain(self.mockTransaction.transactionIdentifier),
            description: "Transaction should be marked as posted"
        )
    }

}

private func match(_ data: PurchasedTransactionData) -> Nimble.Predicate<PurchasedTransactionData> {
    return .init {
        let other = try $0.evaluate()
        let matches = (other?.appUserID == data.appUserID &&
                       other?.presentedOfferingID == data.presentedOfferingID &&
                       other?.source == data.source &&
                       other?.unsyncedAttributes == data.unsyncedAttributes)

        return .init(bool: matches, message: .fail("PurchasedTransactionData do not match"))
    }
}

private extension TransactionPosterResult {

    var wasAlreadyPosted: Bool {
        switch self {
        case .alreadyPosted: return true
        case .success, .failure: return false
        }
    }

}
