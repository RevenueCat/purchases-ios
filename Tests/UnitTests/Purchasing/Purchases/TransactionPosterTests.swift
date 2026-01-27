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
    private var localTransactionMetadataStore: MockLocalTransactionMetadataStore!

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

        let result = try self.handleTransaction(.init())
        expect(result).to(beFailure())
        expect(result.error) == BackendError.missingReceiptFile(self.receiptFetcher.mockReceiptURL)
    }

    func testHandlePurchasedTransaction() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is false because it comes from .queue and no stored metadata existed for that transaction
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == false
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionFromPurchaseInitiationSourceSendsTransactionIdAndSdkOriginated() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(
            transactionData,
            postReceiptSource: .init(isRestore: false, initiationSource: .purchase)
        )
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is true because initiationSource is .purchase
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == true

        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionSendsReceiptIfStoreKit2EnabledButJWSTokenIsMissing() throws {
        self.setUp(observerMode: false, storeKitVersion: .storeKit2)

        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()

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
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.setUp(observerMode: false, storeKitVersion: .storeKit2)
        let jwsRepresentation = UUID().uuidString
        self.mockTransaction = MockStoreTransaction(jwsRepresentation: jwsRepresentation)

        let product = MockSK1Product(mockProductIdentifier: "product")

        let transactionData = PurchasedTransactionData()

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

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is false because it comes from .queue and no stored metadata existed for that transaction
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == false
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionSendsSK2Receipt() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.setUp(observerMode: false, storeKitVersion: .storeKit2)
        let jwsRepresentation = UUID().uuidString
        self.mockTransaction = MockStoreTransaction(jwsRepresentation: jwsRepresentation, environment: .xcode)

        let product = MockSK1Product(mockProductIdentifier: "product")

        let transactionData = PurchasedTransactionData()

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

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is false because it comes from .queue and no stored metadata existed for that transaction
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == false
        expect(self.mockTransaction.finishInvoked) == true
    }

    func testHandlePurchasedTransactionDoesNotFinishNonProcessedConsumables() throws {
        let product = Self.createTestProduct(.consumable)
        let transactionData = PurchasedTransactionData()
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
        let transactionData = PurchasedTransactionData()
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
        let transactionData = PurchasedTransactionData()

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
        let info = Self.mockCustomerInfo.copy(with: .verifiedOnDevice, httpResponseOriginalSource: nil)

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

    func testPostReceiptForPurchaseInSimulatedStore() throws {
        self.setUp(observerMode: false, storeKitVersion: .storeKit2, apiKeyValidationResult: .simulatedStore)
        let purchaseDate = Date()
        let purchaseToken = "test_\(purchaseDate.millisecondsSince1970)_\(UUID().uuidString)"

        self.mockTransaction = MockStoreTransaction(jwsRepresentation: purchaseToken)

        let product = TestStoreProduct(localizedTitle: "Fake product",
                                       price: 9.99,
                                       currencyCode: "USD",
                                       localizedPriceString: "$9.99",
                                       productIdentifier: "fake_product",
                                       productType: .autoRenewableSubscription,
                                       localizedDescription: "Fake product description",
                                       locale: .current)

        let transactionData = PurchasedTransactionData()

        self.productsManager.stubbedProductsCompletionResult = .success([product.toStoreProduct()])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(purchaseToken)
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.productIdentifier) == "fake_product"
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is false because it comes from .queue and no stored metadata existed for that transaction
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == false

        expect(self.receiptFetcher.receiptDataCalled) == false
        expect(self.transactionFetcher.appTransactionJWSCalled.value) == false
    }

    // MARK: - postReceiptFromSyncedSK2Transaction tests

    func testPostReceiptFromSyncedSK2TransactionWithSuccessfulReceipt() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let appTransactionJWS = "test_app_transaction_jws"
        let receiptData = "mock receipt".asData
        let receipt: EncodedAppleReceipt = .receipt(receiptData)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .queue),
            appTransactionJWS: appTransactionJWS
        )
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == receipt
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
    }

    func testPostReceiptFromSyncedSK2TransactionSendsJWS() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.setUp(observerMode: false, storeKitVersion: .storeKit2)
        let jwsRepresentation = UUID().uuidString
        self.mockTransaction = MockStoreTransaction(jwsRepresentation: jwsRepresentation)

        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let appTransactionJWS = "test_app_transaction_jws"
        let receipt: EncodedAppleReceipt = .jws(jwsRepresentation)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .queue),
            appTransactionJWS: appTransactionJWS
        )
        expect(result).to(beSuccess())
        expect(result.value) === Self.mockCustomerInfo

        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.transactionData).to(match(transactionData))
        expect(self.backend.invokedPostReceiptDataParameters?.data) == .jws(jwsRepresentation)
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS
        expect(self.backend.invokedPostReceiptDataParameters?.observerMode) == self.systemInfo.observerMode
    }

    func testPostReceiptFromSyncedSK2TransactionUsesStoredMetadata() throws {
        let product = MockSK1Product(mockProductIdentifier: "original_product")
        let storedProductData = ProductRequestData(
            productIdentifier: "stored_product",
            paymentMode: nil,
            currencyCode: "EUR",
            storeCountry: "DE",
            price: 19.99,
            normalDuration: nil,
            introDuration: nil,
            introDurationType: nil,
            introPrice: nil,
            subscriptionGroup: nil,
            discounts: nil
        )
        let storedTransactionData = PurchasedTransactionData(
            presentedOfferingContext: .init(
                offeringIdentifier: "stored_offering",
                placementIdentifier: "stored_placement",
                targetingContext: nil
            )
        )
        // sdkOriginated is false because this represents a non-SDK purchase
        // (e.g., a paywall purchase with purchasesAreCompletedBy: .myApp)
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: storedProductData,
            transactionData: storedTransactionData,
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .myApp,
            sdkOriginated: false
        )

        // Pre-store metadata
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        let transactionData = PurchasedTransactionData()
        let appTransactionJWS = "test_app_transaction_jws"
        let receiptData = "mock receipt".asData
        let receipt: EncodedAppleReceipt = .receipt(receiptData)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .queue),
            appTransactionJWS: appTransactionJWS
        )
        expect(result).to(beSuccess())

        // Verify that the stored metadata was used
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.productIdentifier) == "stored_product"
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.currencyCode) == "EUR"
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.price) == 19.99
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ) == "stored_offering"
        expect(self.backend.invokedPostReceiptDataParameters?.originalPurchaseCompletedBy) == .myApp
        expect(self.backend.invokedPostReceiptDataParameters?.appTransaction) == appTransactionJWS

        expect(
            self.backend.invokedPostReceiptDataParameters?.associatedTransactionId
        ) == self.mockTransaction.transactionIdentifier

        // sdkOriginated is false because the stored metadata had sdkOriginated = false
        expect(self.backend.invokedPostReceiptDataParameters?.sdkOriginated) == false
    }

    func testPostReceiptFromSyncedSK2TransactionClearsMetadataOnSuccess() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        let transactionData = PurchasedTransactionData()
        let receiptData = "mock receipt".asData
        let receipt: EncodedAppleReceipt = .receipt(receiptData)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .purchase),
            appTransactionJWS: nil
        )
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptFromSyncedSK2TransactionDoesNotFinishTransaction() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let receiptData = "mock receipt".asData
        let receipt: EncodedAppleReceipt = .receipt(receiptData)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .queue),
            appTransactionJWS: nil
        )
        expect(result).to(beSuccess())

        // Verify transaction was NOT finished (unlike handlePurchasedTransaction)
        expect(self.mockTransaction.finishInvoked) == false
    }

    func testPostReceiptFromSyncedSK2TransactionDoesNotFinishTransactionOnFinishableError() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let receiptData = "mock receipt".asData
        let receipt: EncodedAppleReceipt = .receipt(receiptData)

        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Create a finishable error (4xx client error)
        let error: NetworkError = .errorResponse(
            ErrorResponse(
                code: .badRequest,
                originalCode: .init()
            ),
            .invalidRequest
        )
        let finishableError = BackendError.networkError(error)
        expect(finishableError.finishable) == true

        self.backend.stubbedPostReceiptResult = .failure(finishableError)

        let result = try self.postReceiptFromSyncedSK2Transaction(
            transactionData,
            receipt: receipt,
            postReceiptSource: PostReceiptSource(isRestore: false, initiationSource: .queue),
            appTransactionJWS: nil
        )
        expect(result).to(beFailure())

        // Verify transaction was NOT finished even on finishable error
        // This is different from handlePurchasedTransaction which finishes on finishable errors
        expect(self.mockTransaction.finishInvoked) == false
    }

    // MARK: - LocalTransactionMetadata tests

    func testPostReceiptStoresMetadataForPurchaseInitiatedTransaction() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedStoreMetadataParameters.value?.transactionId) ==
            self.mockTransaction.transactionIdentifier
        expect(self.localTransactionMetadataStore.invokedStoreMetadataParameters.value?.metadata).toNot(beNil())
    }

    func testPostReceiptDoesNotStoreMetadataForQueueInitiatedTransactionWithoutOfferingContextOrPaywall() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        // Empty transaction data: no presentedOfferingContext or presentedPaywall
        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == false
    }

    func testPostReceiptStoresMetadataForQueueInitiatedTransactionWithPresentedOfferingContext() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: .init(offeringIdentifier: "test_offering")
        )
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .queue)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedStoreMetadataParameters.value?.transactionId) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptStoresMetadataForQueueInitiatedTransactionWithPresentedPaywall() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let paywallEventCreationData = PaywallEvent.CreationData(
            id: UUID(),
            date: Date()
        )
        let paywallEventData = PaywallEvent.Data(
            paywallIdentifier: "test_paywall_id",
            offeringIdentifier: "test_offering",
            paywallRevision: 1,
            sessionID: UUID(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let paywallEvent = PaywallEvent.impression(paywallEventCreationData, paywallEventData)
        let transactionData = PurchasedTransactionData(presentedPaywall: paywallEvent)
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .queue)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedStoreMetadataParameters.value?.transactionId) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptDoesNotStoreMetadataForRestoreInitiatedTransactionWithoutOfferingContextOrPaywall() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        // Empty transaction data: no presentedOfferingContext or presentedPaywall
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: true, initiationSource: .restore)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == false
    }

    func testPostReceiptUsesStoredMetadataWhenAvailable() throws {
        let product = MockSK1Product(mockProductIdentifier: "original_product")
        let storedProductData = ProductRequestData(
            productIdentifier: "stored_product",
            paymentMode: nil,
            currencyCode: "EUR",
            storeCountry: "DE",
            price: 19.99,
            normalDuration: nil,
            introDuration: nil,
            introDurationType: nil,
            introPrice: nil,
            subscriptionGroup: nil,
            discounts: nil
        )
        let storedTransactionData = PurchasedTransactionData(
            presentedOfferingContext: .init(
                offeringIdentifier: "stored_offering",
                placementIdentifier: "stored_placement",
                targetingContext: nil
            )
        )
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: storedProductData,
            transactionData: storedTransactionData,
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .myApp,
            sdkOriginated: false
        )

        // Pre-store metadata
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())

        // Verify that the stored metadata was used
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.productIdentifier) == "stored_product"
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.currencyCode) == "EUR"
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.price) == 19.99
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ) == "stored_offering"
        expect(self.backend.invokedPostReceiptDataParameters?.originalPurchaseCompletedBy) == .myApp
    }

    func testPostReceiptClearsMetadataOnSuccess() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptClearsMetadataOnFinishableError() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Create a finishable error
        let error: NetworkError = .errorResponse(
            ErrorResponse(
                code: .badRequest,
                originalCode: .init()
            ),
            .invalidRequest
        )
        let finishableError = BackendError.networkError(error)
        self.backend.stubbedPostReceiptResult = .failure(finishableError)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beFailure())

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptDoesNotClearMetadataOnNonFinishableError() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Create a non-finishable error (network error)
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let nonFinishableError = BackendError.networkError(.networkError(networkError))
        self.backend.stubbedPostReceiptResult = .failure(nonFinishableError)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beFailure())

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == false
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 0
    }

    func testPostReceiptClearsExistingMetadataOnSuccess() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptDoesNotStoreMetadataWhenMetadataAlreadyExists() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1

        let transactionData = PurchasedTransactionData()
        let purchaseInitiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: purchaseInitiationSource)
        expect(result).to(beSuccess())

        // Should not store metadata again
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1
    }

    func testPostReceiptFromQueueClearsExistingMetadataWhenMetadataOnSuccessWhenMetadataAlreadyExists() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata (simulating it was stored from a previous purchase attempt)
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        // Transaction is from queue (not purchase-initiated)
        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())

        // Metadata should be cleared on success even for queue-initiated transactions
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptFromQueueClearsExistingMetadataWhenMetadataOnFinishableErrorWhenMetadataAlreadyExists() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata (simulating it was stored from a previous purchase attempt)
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )

        // Transaction is from queue (not purchase-initiated)
        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Create a finishable error (4xx client error)
        let error: NetworkError = .errorResponse(
            ErrorResponse(
                code: .badRequest,
                originalCode: .init()
            ),
            .invalidRequest
        )
        let finishableError = BackendError.networkError(error)
        self.backend.stubbedPostReceiptResult = .failure(finishableError)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beFailure())

        // Metadata should be cleared on finishable error even for queue-initiated transactions
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 1
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) ==
            self.mockTransaction.transactionIdentifier
    }

    func testPostReceiptDoesNotClearNewMetadataWhenCustomerInfoIsComputedOffline() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let transactionData = PurchasedTransactionData()
        let initiationSource = PostReceiptSource(isRestore: false, initiationSource: .purchase)

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Return offline-computed CustomerInfo (server was down, so receipt wasn't actually processed)
        let offlineCustomerInfo = Self.mockCustomerInfo.copy(with: .verifiedOnDevice, httpResponseOriginalSource: nil)
        self.backend.stubbedPostReceiptResult = .success(offlineCustomerInfo)

        let result = try self.handleTransaction(transactionData, postReceiptSource: initiationSource)
        expect(result).to(beSuccess())
        expect(result.value?.isComputedOffline) == true

        // Metadata should be stored for purchase-initiated transactions
        expect(self.localTransactionMetadataStore.invokedStoreMetadata.value) == true

        // But metadata should NOT be cleared because CustomerInfo was computed offline
        // (server didn't process the transaction, so we need to keep metadata for retry)
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == false
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 0
    }

    func testPostReceiptDoesNotClearPreexistingMetadataWhenCustomerInfoIsComputedOffline() throws {
        let product = MockSK1Product(mockProductIdentifier: "product")
        let storedMetadata = LocalTransactionMetadata(
            transactionId: self.mockTransaction.transactionIdentifier,
            productData: ProductRequestData(
                productIdentifier: "stored_product",
                paymentMode: nil,
                currencyCode: "EUR",
                storeCountry: "DE",
                price: 19.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(
                presentedOfferingContext: .init(offeringIdentifier: "stored_offering")
            ),
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        // Pre-store metadata (simulating it was stored from a previous offline purchase attempt)
        self.localTransactionMetadataStore.storeMetadata(
            storedMetadata,
            forTransactionId: self.mockTransaction.transactionIdentifier
        )
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1

        let transactionData = PurchasedTransactionData()

        self.receiptFetcher.shouldReturnReceipt = true
        self.productsManager.stubbedProductsCompletionResult = .success([StoreProduct(sk1Product: product)])

        // Return offline-computed CustomerInfo (server still down)
        let offlineCustomerInfo = Self.mockCustomerInfo.copy(with: .verifiedOnDevice, httpResponseOriginalSource: nil)
        self.backend.stubbedPostReceiptResult = .success(offlineCustomerInfo)

        let result = try self.handleTransaction(transactionData)
        expect(result).to(beSuccess())
        expect(result.value?.isComputedOffline) == true

        // Metadata should NOT be stored again (already exists)
        expect(self.localTransactionMetadataStore.invokedStoreMetadataCount.value) == 1

        // Metadata should NOT be cleared because CustomerInfo was computed offline
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == false
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 0

        // Verify the stored metadata was used in the request
        expect(
            self.backend.invokedPostReceiptDataParameters?.transactionData.presentedOfferingContext?.offeringIdentifier
        ) == "stored_offering"
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.currencyCode) == "EUR"
    }

    // MARK: - postRemainingCachedTransactionMetadata tests

    func testPostRemainingCachedTransactionMetadataReturnsEmptyStreamWhenNoCachedMetadata() async {
        // No metadata stored
        expect(self.localTransactionMetadataStore.getAllStoredMetadata()).to(beEmpty())

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(beEmpty())
        expect(self.backend.invokedPostReceiptData) == false
    }

    func testPostRemainingCachedTransactionMetadataPostsSingleMetadataEntry() async {
        let transactionId = "test_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(haveCount(1))
        expect(results.first?.result).to(beSuccess())
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.productData?.productIdentifier) == "product_1"
        expect(self.backend.invokedPostReceiptDataParameters?.associatedTransactionId) == transactionId
    }

    func testPostRemainingCachedTransactionMetadataPostsMultipleMetadataEntriesSequentially() async {
        let transactionId1 = "test_transaction_1"
        let transactionId2 = "test_transaction_2"
        let transactionId3 = "test_transaction_3"

        let metadata1 = self.createCachedMetadata(transactionId: transactionId1, productIdentifier: "product_1")
        let metadata2 = self.createCachedMetadata(transactionId: transactionId2, productIdentifier: "product_2")
        let metadata3 = self.createCachedMetadata(transactionId: transactionId3, productIdentifier: "product_3")

        self.localTransactionMetadataStore.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.localTransactionMetadataStore.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.localTransactionMetadataStore.storeMetadata(metadata3, forTransactionId: transactionId3)

        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(haveCount(3))
        expect(results.filter { $0.result.error == nil }).to(haveCount(3))
        expect(self.backend.invokedPostReceiptDataCount) == 3
    }

    func testPostRemainingCachedTransactionMetadataRemovesMetadataOnSuccess() async {
        let transactionId = "test_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        for await _ in stream { }

        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) == transactionId
    }

    func testPostRemainingCachedTransactionMetadataRemovesMetadataOnFinishableError() async {
        let transactionId = "test_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)

        // Create a finishable error (4xx client error)
        let error: NetworkError = .errorResponse(
            ErrorResponse(
                code: .badRequest,
                originalCode: .init()
            ),
            .invalidRequest
        )
        let finishableError = BackendError.networkError(error)
        expect(finishableError.finishable) == true
        self.backend.stubbedPostReceiptResult = .failure(finishableError)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(haveCount(1))
        expect(results.first?.result).to(beFailure())
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == true
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataTransactionId.value) == transactionId
    }

    func testPostRemainingCachedTransactionMetadataDoesNotRemoveMetadataOnNonFinishableError() async {
        let transactionId = "test_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)

        // Create a non-finishable error (network error)
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let nonFinishableError = BackendError.networkError(.networkError(networkError))
        expect(nonFinishableError.finishable) == false
        self.backend.stubbedPostReceiptResult = .failure(nonFinishableError)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(haveCount(1))
        expect(results.first?.result).to(beFailure())
        expect(self.localTransactionMetadataStore.invokedRemoveMetadata.value) == false
    }

    func testPostRemainingCachedTransactionMetadataContinuesAfterFailure() async {
        let transactionId1 = "test_transaction_1"
        let transactionId2 = "test_transaction_2"

        let metadata1 = self.createCachedMetadata(transactionId: transactionId1, productIdentifier: "product_1")
        let metadata2 = self.createCachedMetadata(transactionId: transactionId2, productIdentifier: "product_2")

        self.localTransactionMetadataStore.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.localTransactionMetadataStore.storeMetadata(metadata2, forTransactionId: transactionId2)

        // Stub a non-finishable error - this simulates a network failure
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let nonFinishableError = BackendError.networkError(.networkError(networkError))
        self.backend.stubbedPostReceiptResult = .failure(nonFinishableError)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        // Both transactions should have been attempted despite failures
        expect(results).to(haveCount(2))
        expect(self.backend.invokedPostReceiptDataCount) == 2

        // Both results should be failures
        expect(results[0].result).to(beFailure())
        expect(results[1].result).to(beFailure())

        // Verify both distinct transactions were posted (proves continuation after first failure)
        let postedTransactionIds = self.backend.invokedPostReceiptDataParametersList.map {
            $0.associatedTransactionId
        }
        expect(postedTransactionIds).to(contain(transactionId1))
        expect(postedTransactionIds).to(contain(transactionId2))

        // Non-finishable errors should NOT remove metadata (will retry later)
        expect(self.localTransactionMetadataStore.invokedRemoveMetadataCount.value) == 0
    }

    func testPostRemainingCachedTransactionMetadataUsesCorrectPostReceiptSource() async {
        let transactionId = "test_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "test_user",
            isRestore: true
        )

        for await _ in stream { }

        expect(self.backend.invokedPostReceiptDataParameters?.postReceiptSource.isRestore) == true
        expect(self.backend.invokedPostReceiptDataParameters?.postReceiptSource.initiationSource) == .queue
        expect(self.backend.invokedPostReceiptDataParameters?.appUserID) == "test_user"
    }

    func testPostRemainingCachedTransactionMetadataUsesStoredReceipt() async {
        let transactionId = "test_transaction_1"
        let receiptData = "stored_receipt_data".asData
        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: ProductRequestData(
                productIdentifier: "product_1",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt(receiptData),
            originalPurchasesAreCompletedBy: .myApp,
            sdkOriginated: true
        )

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        for await _ in stream { }

        expect(self.backend.invokedPostReceiptDataParameters?.data) == .receipt(receiptData)
        expect(self.backend.invokedPostReceiptDataParameters?.originalPurchaseCompletedBy) == .myApp
    }

    func testPostRemainingCachedTransactionMetadataReturnsTransactionDataInResults() async {
        let transactionId = "test_transaction_1"
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: .init(offeringIdentifier: "test_offering"),
            unsyncedAttributes: ["$email": SubscriberAttribute(withKey: "$email", value: "test@test.com")],
            aadAttributionToken: "test_token"
        )
        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: ProductRequestData(
                productIdentifier: "product_1",
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: transactionData,
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        self.localTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)

        let stream = self.poster.postRemainingCachedTransactionMetadata(
            appUserID: "user",
            isRestore: false
        )

        var results: [CachedTransactionMetadataPostResult] = []
        for await result in stream {
            results.append(result)
        }

        expect(results).to(haveCount(1))
        let resultTransactionData = results.first?.transactionData
        expect(resultTransactionData?.presentedOfferingContext?.offeringIdentifier) == "test_offering"
        expect(resultTransactionData?.unsyncedAttributes).toNot(beNil())
        expect(resultTransactionData?.aadAttributionToken) == "test_token"
    }

}

// MARK: -

private extension TransactionPosterTests {

    func setUp(observerMode: Bool,
               storeKitVersion: StoreKitVersion = .default,
               apiKeyValidationResult: Configuration.APIKeyValidationResult = .validApplePlatform) {
        self.operationDispatcher = .init()
        self.systemInfo = .init(finishTransactions: !observerMode,
                                storeKitVersion: storeKitVersion,
                                apiKeyValidationResult: apiKeyValidationResult)
        self.productsManager = .init(diagnosticsTracker: nil, systemInfo: self.systemInfo, requestTimeout: 0)
        self.receiptFetcher = .init(requestFetcher: .init(operationDispatcher: self.operationDispatcher),
                                    systemInfo: self.systemInfo)
        self.transactionFetcher = .init()
        self.backend = .init()
        self.paymentQueueWrapper = .init()
        self.localTransactionMetadataStore = .init()

        self.poster = .init(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            transactionFetcher: self.transactionFetcher,
            backend: self.backend,
            paymentQueueWrapper: .right(self.paymentQueueWrapper),
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher,
            localTransactionMetadataStore: self.localTransactionMetadataStore
        )
    }

    func handleTransaction(
        _ data: PurchasedTransactionData,
        postReceiptSource: PostReceiptSource = .init(isRestore: false, initiationSource: .queue)
    ) throws -> Result<CustomerInfo, BackendError> {
        let result = waitUntilValue { completion in
            self.poster.handlePurchasedTransaction(
                self.mockTransaction,
                data: data,
                postReceiptSource: postReceiptSource,
                currentUserID: "user"
            ) {
                completion($0)
            }
        }

        return try XCTUnwrap(result)
    }

    func postReceiptFromSyncedSK2Transaction(
        _ data: PurchasedTransactionData,
        receipt: EncodedAppleReceipt,
        postReceiptSource: PostReceiptSource = .init(isRestore: false, initiationSource: .queue),
        appTransactionJWS: String?
    ) throws -> Result<CustomerInfo, BackendError> {
        let result = waitUntilValue { completion in
            self.poster.postReceiptFromSyncedSK2Transaction(
                self.mockTransaction,
                data: data,
                receipt: receipt,
                postReceiptSource: postReceiptSource,
                appTransactionJWS: appTransactionJWS,
                currentUserID: "user"
            ) {
                completion($0)
            }
        }

        return try XCTUnwrap(result)
    }

    static func createTestProduct(_ productType: StoreProduct.ProductType) -> TestStoreProduct {
        return .init(localizedTitle: "Title",
                     price: 1.99,
                     currencyCode: "USD",
                     localizedPriceString: "$1.99",
                     productIdentifier: "product",
                     productType: productType,
                     localizedDescription: "Description",
                     locale: .init(identifier: "en_US"))
    }

    func createCachedMetadata(
        transactionId: String,
        productIdentifier: String
    ) -> LocalTransactionMetadata {
        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: ProductRequestData(
                productIdentifier: productIdentifier,
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt_\(transactionId)".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )
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
                            sandboxEnvironmentDetector: self.systemInfo,
                            httpResponseOriginalSource: .mainServer)
    }

}

private func match(_ data: PurchasedTransactionData) -> Nimble.Matcher<PurchasedTransactionData> {
    return .init {
        let other = try $0.evaluate()
        let matches = (other?.presentedOfferingContext == data.presentedOfferingContext &&
                       other?.unsyncedAttributes == data.unsyncedAttributes)

        return .init(bool: matches, message: .fail("PurchasedTransactionData do not match"))
    }
}
