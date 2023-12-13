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
    private var transactionFetcher: MockStoreKit2TransactionFetcher!
    private var receiptFetcher: MockReceiptFetcher!
    private var backend: MockBackend!
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
        expect(result).to(beFailure())
        expect(result.error) == BackendError.missingReceiptFile(self.receiptFetcher.mockReceiptURL)
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
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionSendsReceiptIfJWSSettingEnabledButJWSTokenIsMissing() throws {
        self.setUp(observerMode: false, storeKitVersion: .storeKit2)

        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        let receiptData = "mock receipt".asData
        self.receiptFetcher.shouldReturnReceipt = true
        self.receiptFetcher.mockReceiptData = receiptData
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .receipt(receiptData)
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionSendsJWS() throws {
        self.setUp(observerMode: false, storeKitVersion: .storeKit2)
        let jwsRepresentation = UUID().uuidString
        self.mockTransaction = MockStoreTransaction(jwsRepresentation: jwsRepresentation)

        let product = MockSK1Product(mockProductIdentifier: "product")

        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        self.receiptFetcher.shouldReturnReceipt = false
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(jwsRepresentation)
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionSendsSK2Receipt() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUp(observerMode: false, storeKitVersion: .storeKit2)
        let jwsRepresentation = UUID().uuidString
        self.mockTransaction = MockStoreTransaction(jwsRepresentation: jwsRepresentation, environment: .xcode)

        let product = MockSK1Product(mockProductIdentifier: "product")

        let transactionData = PurchasedTransactionData(
            appUserID: "user",
            source: .init(isRestore: false, initiationSource: .queue)
        )

        let receipt = StoreKit2Receipt(
            environment: .xcode,
            subscriptionStatusBySubscriptionGroupId: [
                "123_subscription_group_id": [
                    .init(state: .subscribed,
                          renewalInfoJWSToken: "123_renewal_info_jws_token",
                          transactionJWSToken: "123_transaction_jws_token")
                ]
            ],
            transactions: ["123_transaction_jws_token"],
            bundleId: "123_bundle_id",
            originalApplicationVersion: "123_original_application_version",
            originalPurchaseDate: Date(timeIntervalSince1970: 123))

        self.receiptFetcher.shouldReturnReceipt = false
        self.transactionFetcher.stubbedReceipt = receipt
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .sk2receipt(receipt)
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true
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
        expect(result).to(beSuccess())
        expect(result.value) === customerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == false

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
        expect(result).to(beSuccess())
        expect(result.value) === customerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
        expect(self.mockTransaction.finishInvoked) == true
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
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == true
        expect(self.mockTransaction.finishInvoked) == false
    }

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

    func setUp(observerMode: Bool, storeKitVersion: StoreKitVersion = .default) {
        self.operationDispatcher = .init()
        self.systemInfo = .init(finishTransactions: !observerMode, storeKitVersion: storeKitVersion)
        self.productsManager = .init(systemInfo: self.systemInfo, requestTimeout: 0)
        self.receiptFetcher = .init(requestFetcher: .init(operationDispatcher: self.operationDispatcher),
                                    systemInfo: self.systemInfo)
        self.transactionFetcher = .init()
        self.backend = .init()
        self.paymentQueueWrapper = .init()

        self.poster = .init(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            transactionFetcher: self.transactionFetcher,
            backend: self.backend,
            paymentQueueWrapper: .right(self.paymentQueueWrapper),
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher
        )
    }

    func handleTransaction(_ data: PurchasedTransactionData) throws -> Result<CustomerInfo, BackendError> {
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
