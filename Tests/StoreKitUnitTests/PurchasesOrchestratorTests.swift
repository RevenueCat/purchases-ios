//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorTests.swift
//
//  Created by Andrés Boedo on 1/9/21.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
class PurchasesOrchestratorTests: StoreKitConfigTestCase {

    private var productsManager: MockProductsManager!
    private var storeKit1Wrapper: MockStoreKit1Wrapper!
    private var systemInfo: MockSystemInfo!
    private var subscriberAttributesManager: MockSubscriberAttributesManager!
    private var attribution: Attribution!
    private var operationDispatcher: MockOperationDispatcher!
    private var receiptFetcher: MockReceiptFetcher!
    private var customerInfoManager: MockCustomerInfoManager!
    private var backend: MockBackend!
    private var offerings: MockOfferingsAPI!
    private var currentUserProvider: MockCurrentUserProvider!
    private var transactionsManager: MockTransactionsManager!
    private var deviceCache: MockDeviceCache!
    private var mockManageSubsHelper: MockManageSubscriptionsHelper!
    private var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!
    private var mockOfferingsManager: MockOfferingsManager!

    private var orchestrator: PurchasesOrchestrator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpSystemInfo()

        let mockUserID = "appUserID"
        productsManager = MockProductsManager(systemInfo: systemInfo,
                                              requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        operationDispatcher = MockOperationDispatcher()
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: systemInfo)
        deviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.systemInfo)
        backend = MockBackend()
        offerings = try XCTUnwrap(self.backend.offerings as? MockOfferingsAPI)

        mockOfferingsManager = MockOfferingsManager(deviceCache: deviceCache,
                                                    operationDispatcher: operationDispatcher,
                                                    systemInfo: self.systemInfo,
                                                    backend: backend,
                                                    offeringsFactory: OfferingsFactory(),
                                                    productsManager: productsManager)

        customerInfoManager = MockCustomerInfoManager(operationDispatcher: OperationDispatcher(),
                                                      deviceCache: deviceCache,
                                                      backend: backend,
                                                      systemInfo: systemInfo)
        currentUserProvider = MockCurrentUserProvider(mockAppUserID: mockUserID)
        transactionsManager = MockTransactionsManager(receiptParser: MockReceiptParser())
        let attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                        systemInfo: systemInfo)
        subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: backend,
            deviceCache: deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: attributionFetcher,
            attributionDataMigrator: MockAttributionDataMigrator())
        let attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                                  currentUserProvider: currentUserProvider,
                                                  backend: backend,
                                                  attributionFetcher: attributionFetcher,
                                                  subscriberAttributesManager: subscriberAttributesManager)
        attribution = Attribution(subscriberAttributesManager: subscriberAttributesManager,
                                  currentUserProvider: MockCurrentUserProvider(mockAppUserID: mockUserID),
                                  attributionPoster: attributionPoster)
        mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: systemInfo,
                                                             customerInfoManager: customerInfoManager,
                                                             currentUserProvider: currentUserProvider)
        mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: systemInfo,
                                                                    customerInfoManager: customerInfoManager,
                                                                    currentUserProvider: currentUserProvider)
        self.setupStoreKit1Wrapper()
        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()
    }

    fileprivate func setUpStoreKit2Listener() {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self.orchestrator._storeKit2TransactionListener = MockStoreKit2TransactionListener()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var mockStoreKit2TransactionListener: MockStoreKit2TransactionListener? {
        return self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
    }

    fileprivate func setUpSystemInfo(
        finishTransactions: Bool = true,
        storeKit2Setting: StoreKit2Setting = .default
    ) throws {
        let platformInfo = Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3")

        self.systemInfo = try MockSystemInfo(platformInfo: platformInfo,
                                             finishTransactions: finishTransactions,
                                             storeKit2Setting: storeKit2Setting)
        self.systemInfo.stubbedIsSandbox = true
    }

    fileprivate func setupStoreKit1Wrapper() {
        storeKit1Wrapper = MockStoreKit1Wrapper()
        storeKit1Wrapper.mockAddPaymentTransactionState = .purchased
        storeKit1Wrapper.mockCallUpdatedTransactionInstantly = true
    }

    fileprivate func setUpOrchestrator() {
        self.orchestrator = PurchasesOrchestrator(productsManager: self.productsManager,
                                                  paymentQueueWrapper: .left(self.storeKit1Wrapper),
                                                  systemInfo: self.systemInfo,
                                                  subscriberAttributes: self.attribution,
                                                  operationDispatcher: self.operationDispatcher,
                                                  receiptFetcher: self.receiptFetcher,
                                                  customerInfoManager: self.customerInfoManager,
                                                  backend: self.backend,
                                                  currentUserProvider: self.currentUserProvider,
                                                  transactionsManager: self.transactionsManager,
                                                  deviceCache: self.deviceCache,
                                                  offeringsManager: self.mockOfferingsManager,
                                                  manageSubscriptionsHelper: self.mockManageSubsHelper,
                                                  beginRefundRequestHelper: self.mockBeginRefundRequestHelper)
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    fileprivate func setUpOrchestrator(
        storeKit2TransactionListener: StoreKit2TransactionListener,
        storeKit2StorefrontListener: StoreKit2StorefrontListener
    ) {
        self.orchestrator = PurchasesOrchestrator(productsManager: self.productsManager,
                                                  paymentQueueWrapper: .left(self.storeKit1Wrapper),
                                                  systemInfo: self.systemInfo,
                                                  subscriberAttributes: self.attribution,
                                                  operationDispatcher: self.operationDispatcher,
                                                  receiptFetcher: self.receiptFetcher,
                                                  customerInfoManager: self.customerInfoManager,
                                                  backend: self.backend,
                                                  currentUserProvider: self.currentUserProvider,
                                                  transactionsManager: self.transactionsManager,
                                                  deviceCache: self.deviceCache,
                                                  offeringsManager: self.mockOfferingsManager,
                                                  manageSubscriptionsHelper: self.mockManageSubsHelper,
                                                  beginRefundRequestHelper: self.mockBeginRefundRequestHelper,
                                                  storeKit2TransactionListener: storeKit2TransactionListener,
                                                  storeKit2StorefrontListener: storeKit2StorefrontListener)
        self.storeKit1Wrapper.delegate = self.orchestrator
    }

    // MARK: - tests

    func testPurchaseSK1PackageSendsReceiptToBackendIfSuccessful() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk1Product()
        let storeProduct = try await fetchSk1StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = storeKit1Wrapper.payment(with: product)

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    func testGetSK1PromotionalOffer() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))

        let product = try await fetchSk1Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        let result = try await Async.call { completion in
            orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                          product: StoreProduct(sk1Product: product),
                                          completion: completion)
        }

        expect(result.signedData.identifier) == storeProductDiscount.offerIdentifier

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
    }

    func testGetSK1PromotionalOfferFailsWithIneligibleDiscount() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        self.offerings.stubbedPostOfferCompletionResult = .failure(
            .networkError(
                .errorResponse(
                    .init(code: .userIneligibleForPromoOffer,
                          originalCode: BackendErrorCode.userIneligibleForPromoOffer.rawValue),
                    .success
                )
            )
        )

        let product = try await self.fetchSk1Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: product.priceLocale.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 2,
                                                            type: .promotional)

        do {
            _ = try await Async.call { completion in
                self.orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                   product: StoreProduct(sk1Product: product),
                                                   completion: completion)
            }

            fail("Expected error")
        } catch let purchasesError as PurchasesError {
            expect(purchasesError.error).to(matchError(ErrorCode.ineligibleError))
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testPurchaseSK1PackageWithDiscountSendsReceiptToBackendIfSuccessful() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  promotionalOffer: offer,
                                  package: package,
                                  wrapper: self.storeKit1Wrapper) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    func testPurchaseSK1PackageWithNoProductIdentifierDoesNotPostReceipt() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = self.storeKit1Wrapper.payment(with: product)
        payment.productIdentifier = ""

        let (transaction, customerInfo, error, cancelled) =
        try await withCheckedThrowingContinuation { continuation in
            self.orchestrator.purchase(
                sk1Product: product,
                payment: payment,
                package: package,
                wrapper: self.storeKit1Wrapper
            ) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        // Internally PurchasesOrchestrator uses product identifiers for callback keys
        // When the transaction comes back, its payment is the only source for product identifier.
        // There is no point starting the purchase if we can't retrieve the product identifier from it.
        expect(transaction).to(beNil())
        expect(customerInfo).to(beNil())
        expect(error).to(matchError(ErrorCode.storeProblemError))
        expect(cancelled) == false

        expect(self.backend.invokedPostReceiptDataCount) == 0
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCorrectValues() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockTransaction = try await createTransactionWithPurchase()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, userCancelled) = try await orchestrator.purchase(sk2Product: product,
                                                                                         promotionalOffer: nil)

        expect(transaction?.sk2Transaction) == mockTransaction
        expect(userCancelled) == false

        let expectedCustomerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
        expect(customerInfo) == expectedCustomerInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageHandlesPurchaseResult() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let storeProduct = StoreProduct.from(product: try await fetchSk2StoreProduct())
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(product: storeProduct,
                                  package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)
        expect(mockListener.invokedHandle) == true
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockListener = try XCTUnwrap(orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener)

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        mockListener.mockTransaction.value = try await self.createTransactionWithPurchase()

        let product = try await fetchSk2Product()

        _ = try await orchestrator.purchase(sk2Product: product, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .always

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageRetriesReceiptFetchIfEnabled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.systemInfo = try .init(
            platformInfo: nil,
            finishTransactions: false,
            storeKit2Setting: .enabledForCompatibleDevices,
            dangerousSettings: .init(autoSyncPurchases: true,
                                     internalSettings: .init(enableReceiptFetchRetry: true))
        )

        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        mockListener.mockTransaction.value = try await self.createTransactionWithPurchase()

        let product = try await self.fetchSk2Product()

        _ = try await orchestrator.purchase(sk2Product: product, promotionalOffer: nil)

        expect(self.receiptFetcher.receiptDataCalled) == true
        expect(self.receiptFetcher.receiptDataReceivedRefreshPolicy) == .retryUntilProductIsFound(
            productIdentifier: product.id,
            maximumRetries: PurchasesOrchestrator.receiptRetryCount,
            sleepDuration: PurchasesOrchestrator.receiptRetrySleepDuration
        )

        expect(self.backend.invokedPostReceiptDataCount) == 1
        expect(self.backend.invokedPostReceiptDataParameters?.productData).toNot(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSkipsIfPurchaseFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.failTransactionsEnabled = true
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await fetchSk2Product()
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        do {
            _ = try await orchestrator.purchase(sk2Product: product, promotionalOffer: offer)
            XCTFail("Expected error")
        } catch {
            expect(self.backend.invokedPostReceiptData) == false
            let mockListener = try XCTUnwrap(
                orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
            )
            expect(mockListener.invokedHandle) == false
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageWithInvalidPromotionalOfferSignatureThrowsError() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()
        let offer = PromotionalOffer.SignedData(
            identifier: "identifier \(Int.random(in: 0..<1000))",
            keyIdentifier: "key identifier \(Int.random(in: 0..<1000))",
            nonce: .init(),
            // This should be base64
            signature: "signature \(Int.random(in: 0..<1000))",
            timestamp: Int.random(in: 0..<1000)
        )

        do {
            _ = try await orchestrator.purchase(sk2Product: product, promotionalOffer: offer)
            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.invalidPromotionalOfferError))
            expect(error.localizedDescription)
                .to(contain("The signature generated by RevenueCat could not be decoded: \(offer.signature)"))
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCustomerInfoForFailedTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.customerInfoManager.stubbedCustomerInfoResult = .success(self.mockCustomerInfo)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, cancelled) = try await self.orchestrator.purchase(sk2Product: product,
                                                                                          promotionalOffer: nil)

        expect(transaction).to(beNil())
        expect(customerInfo) == self.mockCustomerInfo
        expect(cancelled) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsMissingReceiptErrorIfSendReceiptFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let product = try await fetchSk2Product()

        let mockListener = try XCTUnwrap(
            self.orchestrator.storeKit2TransactionListener as? MockStoreKit2TransactionListener
        )

        self.receiptFetcher.shouldReturnReceipt = false
        mockListener.mockTransaction.value = try await self.createTransactionWithPurchase()

        do {
            _ = try await self.orchestrator.purchase(sk2Product: product, promotionalOffer: nil)

            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.missingReceiptFileError))
            expect(mockListener.invokedHandle) == true
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDelegate() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setUpStoreKit2Listener()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        let transaction = MockStoreTransaction()

        try await self.orchestrator.storeKit2TransactionListener(
            self.mockStoreKit2TransactionListener!,
            updatedTransaction: transaction
        )

        expect(transaction.finishInvoked) == true
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.isRestore) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDelegateWithObserverMode() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try self.setUpSystemInfo(finishTransactions: false, storeKit2Setting: .enabledForCompatibleDevices)

        self.setUpOrchestrator()
        self.setUpStoreKit2Listener()

        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        let transaction = MockStoreTransaction()

        try await self.orchestrator.storeKit2TransactionListener(
            self.mockStoreKit2TransactionListener!,
            updatedTransaction: transaction
        )

        expect(transaction.finishInvoked) == false
        expect(self.backend.invokedPostReceiptData) == true
        expect(self.backend.invokedPostReceiptDataParameters?.isRestore) == true
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptResult = .success(mockCustomerInfo)
        offerings.stubbedPostOfferCompletionResult = .success(("signature", "identifier", UUID(), 12345))

        let storeProduct = try await self.fetchSk2StoreProduct()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            currencyCode: storeProduct.currencyCode,
                                                            price: 11.1,
                                                            localizedPriceString: "$11.10",
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month),
                                                            numberOfPeriods: 3,
                                                            type: .promotional)

        _ = try await orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                    product: storeProduct)

        expect(self.offerings.invokedPostOfferCount) == 1
        expect(self.offerings.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
        expect(self.offerings.invokedPostOfferParameters?.data).toNot(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testClearCachedProductsAndOfferingsAfterStorefrontChangesWithSK2() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.orchestrator.storefrontDidUpdate()

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    func testClearCachedProductsAndOfferingsAfterStorefrontChangesWithSK1() async throws {
        self.orchestrator.storeKit1WrapperDidChangeStorefront(storeKit1Wrapper)

        expect(self.mockOfferingsManager.invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount) == 1
        expect(self.productsManager.invokedClearCacheCount) == 1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testDoesNotListenForSK2TransactionsWithSK2Disabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        try self.setUpSystemInfo(storeKit2Setting: .disabled)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedListenForTransactions) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testDoesNotListenForSK2TransactionsWithSK2EnabledOnlyForOptimizations() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        try self.setUpSystemInfo(storeKit2Setting: .enabledOnlyForOptimizations)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedListenForTransactions) == false
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testListensForSK2TransactionsWithSK2Enabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transactionListener = MockStoreKit2TransactionListener()

        try self.setUpSystemInfo(storeKit2Setting: .enabledForCompatibleDevices)

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil))

        expect(transactionListener.invokedListenForTransactions) == true
        expect(transactionListener.invokedListenForTransactionsCount) == 1
    }

    #if os(iOS) || targetEnvironment(macCatalyst)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func testShowManageSubscriptionsCallsCompletionWithErrorIfThereIsAFailure() {
        let message = "Failed to get managementURL from CustomerInfo. Details: customerInfo is nil."
        mockManageSubsHelper.mockError = ErrorUtils.customerInfoError(withMessage: message)

        let receivedError: Error? = waitUntilValue { completed in
            self.orchestrator.showManageSubscription { error in
                completed(error)
            }
        }

        expect(receivedError).to(matchError(ErrorCode.customerInfoError))
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForProductCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let refundStatus = try await orchestrator.beginRefundRequest(forProduct: "1234")
        expect(refundStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForProductCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequest(forProduct: "1235")
            XCTFail("beginRefundRequestForProduct should have thrown an error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForEntitlementCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let receivedStatus = try await orchestrator.beginRefundRequest(forEntitlement: "1234")
        expect(receivedStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForEntitlementCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequest(forEntitlement: "1234")
            XCTFail("beginRefundRequestForEntitlement should have thrown error")
        } catch {
            expect(error).toNot(beNil())
            expect(error).to(matchError(expectedError))
        }

    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForActiveEntitlementCompletesWithoutErrorAndPassesThroughStatusIfSuccessful() async throws {
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.mockRefundRequestStatus = expectedStatus

        let receivedStatus = try await orchestrator.beginRefundRequestForActiveEntitlement()
        expect(receivedStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundForActiveEntitlementCompletesWithErrorIfThereIsAFailure() async {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.mockError = expectedError

        do {
            _ = try await orchestrator.beginRefundRequestForActiveEntitlement()
            XCTFail("beginRefundRequestForActiveEntitlement should have thrown error")
        } catch {
            expect(error).toNot(beNil())
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription).to(equal(expectedError.localizedDescription))
        }
    }

    #endif

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsNotDefined() async throws {
        let logger = TestLogHandler()

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        logger.verifyMessageWasNotLogged(
            Strings
                .restore
                .restorepurchases_called_with_allow_sharing_appstore_account_false_warning
        )
    }

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsTrue() async throws {
        let logger = TestLogHandler()

        self.orchestrator.allowSharingAppStoreAccount = true

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        logger.verifyMessageWasNotLogged(
            Strings
                .restore
                .restorepurchases_called_with_allow_sharing_appstore_account_false_warning
        )
    }

    func testRestorePurchasesLogsWarningIfAllowSharingAppStoreAccountIsFalse() async throws {
        let logger = TestLogHandler()

        self.orchestrator.allowSharingAppStoreAccount = false

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        logger.verifyMessageWasLogged(
            Strings
                .restore
                .restorepurchases_called_with_allow_sharing_appstore_account_false_warning,
            level: .warn
        )
    }

}

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *)
private extension PurchasesOrchestratorTests {

    @MainActor
    func fetchSk1Product() async throws -> SK1Product {
        return MockSK1Product(
            mockProductIdentifier: Self.productID,
            mockSubscriptionGroupIdentifier: "group1"
        )
    }

    @MainActor
    func fetchSk1StoreProduct() async throws -> SK1StoreProduct {
        return try await SK1StoreProduct(sk1Product: fetchSk1Product())
    }

    var mockCustomerInfo: CustomerInfo {
        // swiftlint:disable:next force_try
        try! CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])
    }

}
