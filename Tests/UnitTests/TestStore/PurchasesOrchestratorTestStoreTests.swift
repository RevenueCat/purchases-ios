//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorTestStoreTests.swift
//
//  Created by Antonio Pallares on 4/8/25.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class PurchasesOrchestratorTestStoreTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var productsManager: MockProductsManager!
    private var paymentQueueWrapper: MockPaymentQueueWrapper!
    private var testStorePurchaseHandler: MockTestStorePurchaseHandler!
    private var subscriberAttributesManager: MockSubscriberAttributesManager!
    private var backend: MockBackend!
    private var deviceCache: MockDeviceCache!
    private var attributionFetcher: MockAttributionFetcher!
    private var attribution: Attribution!
    private var currentUserProvider: MockCurrentUserProvider!
    private var receiptParser: MockReceiptParser!
    private var receiptFetcher: MockReceiptFetcher!
    private var mockTransactionFetcher: MockStoreKit2TransactionFetcher!
    private var customerInfoManager: MockCustomerInfoManager!
    private var transactionPoster: TransactionPoster!
    private var transactionsManager: MockTransactionsManager!
    private var operationDispatcher: MockOperationDispatcher!
    private var diagnosticsTracker: DiagnosticsTrackerType?
    private var paywallEventsManager: PaywallEventsManagerType?
    private var mockOfferingsManager: MockOfferingsManager!
    private var mockManageSubsHelper: MockManageSubscriptionsHelper!
    private var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!
    private var mockStoreMessagesHelper: MockStoreMessagesHelper!
    private var mockWinBackOfferEligibilityCalculator: MockWinBackOfferEligibilityCalculator!
    private var webPurchaseRedemptionHelper: MockWebPurchaseRedemptionHelper!
    private let mockDateProvider = MockDateProvider(stubbedNow: eventTimestamp1,
                                                    subsequentNows: eventTimestamp2)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var mockPaywallEventsManager: MockPaywallEventsManager {
        get throws {
            return try XCTUnwrap(self.paywallEventsManager as? MockPaywallEventsManager)
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var mockDiagnosticsTracker: MockDiagnosticsTracker {
        get throws {
            return try XCTUnwrap(self.diagnosticsTracker as? MockDiagnosticsTracker)
        }
    }

    private static let mockUserID = "appUserID"
    private static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    private static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694032321)

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = MockSystemInfo(platformInfo: Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3"),
                                         finishTransactions: true,
                                         storeKitVersion: .storeKit2,
                                         apiKeyValidationResult: .testStore)

        self.productsManager = MockProductsManager(diagnosticsTracker: nil,
                                                   systemInfo: self.systemInfo,
                                                   requestTimeout: Configuration.storeKitRequestTimeoutDefault)

        self.paymentQueueWrapper = .init()

        self.testStorePurchaseHandler = MockTestStorePurchaseHandler()

        self.backend = MockBackend()
        self.deviceCache = MockDeviceCache(systemInfo: self.systemInfo)
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: Self.mockUserID)
        self.receiptParser = MockReceiptParser()
        self.receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: self.systemInfo)
        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        self.operationDispatcher = MockOperationDispatcher()
        self.transactionPoster = TransactionPoster(
            productsManager: self.productsManager,
            receiptFetcher: self.receiptFetcher,
            transactionFetcher: self.mockTransactionFetcher,
            backend: self.backend,
            paymentQueueWrapper: .right(self.paymentQueueWrapper),
            systemInfo: self.systemInfo,
            operationDispatcher: self.operationDispatcher
        )
        self.transactionsManager = MockTransactionsManager(receiptParser: self.receiptParser)
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            self.paywallEventsManager = MockPaywallEventsManager()
            self.diagnosticsTracker = MockDiagnosticsTracker()
        } else {
            self.paywallEventsManager = nil
            self.diagnosticsTracker = nil
        }
        self.mockOfferingsManager = MockOfferingsManager(deviceCache: self.deviceCache,
                                                         operationDispatcher: self.operationDispatcher,
                                                         systemInfo: self.systemInfo,
                                                         backend: self.backend,
                                                         offeringsFactory: OfferingsFactory(),
                                                         productsManager: self.productsManager,
                                                         diagnosticsTracker: self.diagnosticsTracker)

        self.attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                         systemInfo: self.systemInfo)
        self.subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: MockAttributionDataMigrator())
        let attributionPoster = AttributionPoster(deviceCache: self.deviceCache,
                                                  currentUserProvider: self.currentUserProvider,
                                                  backend: self.backend,
                                                  attributionFetcher: self.attributionFetcher,
                                                  subscriberAttributesManager: self.subscriberAttributesManager,
                                                  systemInfo: self.systemInfo)
        self.attribution = Attribution(subscriberAttributesManager: self.subscriberAttributesManager,
                                       currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.mockUserID),
                                       attributionPoster: attributionPoster,
                                       systemInfo: self.systemInfo)

        self.customerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: OperationDispatcher(),
            deviceCache: self.deviceCache,
            backend: self.backend,
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: self.transactionPoster,
            systemInfo: self.systemInfo
        )

        self.mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: self.systemInfo,
                                                                  customerInfoManager: self.customerInfoManager,
                                                                  currentUserProvider: self.currentUserProvider)
        self.mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: self.systemInfo,
                                                                         customerInfoManager: self.customerInfoManager,
                                                                         currentUserProvider: self.currentUserProvider)
        self.mockStoreMessagesHelper = .init()
        self.mockWinBackOfferEligibilityCalculator = MockWinBackOfferEligibilityCalculator()
        self.webPurchaseRedemptionHelper = MockWebPurchaseRedemptionHelper()
    }

    private func createTestStoreProduct() -> StoreProduct {
        let testProduct = TestStoreProduct(
            localizedTitle: "Test Product",
            price: 9.99,
            localizedPriceString: "$9.99",
            productIdentifier: "test.product",
            productType: .autoRenewableSubscription,
            localizedDescription: "Test subscription"
        )
        return testProduct.toStoreProduct()
    }

#if TEST_STORE

    // MARK: - PurchasesOrchestrator + API Key type

    func testPurchaseWithTestStoreProductAndTestAPIKeyCallsTestStorePurchaseHandler() async {
        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let mockTransaction = Self.createMockTestStoreTransaction()
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .success(StoreTransaction(mockTransaction))

        let expectation = XCTestExpectation(description: "Purchase completion")

        orchestrator.purchase(
            product: testProduct,
            package: nil,
            trackDiagnostics: false
        ) { _, _, _, _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertTrue(self.testStorePurchaseHandler.invokedPurchase.value)
        XCTAssertEqual(self.testStorePurchaseHandler.invokedPurchaseProduct.value?.productIdentifier, "test.product")
    }

    func testPurchaseWithTestStoreProductAndNonTestAPIKeyReturnsError() async {
        self.systemInfo = MockSystemInfo(platformInfo: Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3"),
                                         finishTransactions: true,
                                         storeKitVersion: .storeKit2,
                                         apiKeyValidationResult: .validApplePlatform)

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let expectation = XCTestExpectation(description: "Purchase completion")

        orchestrator.purchase(
            product: testProduct,
            package: nil,
            trackDiagnostics: false
        ) { _, _, error, _ in
            expect(error?.code) == ErrorCode.productNotAvailableForPurchaseError.rawValue
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertFalse(self.testStorePurchaseHandler.invokedPurchase.value)
    }

    func testPurchaseWithTestStoreProductAndOtherPlatformsAPIKeyReturnsError() async {
        self.systemInfo = MockSystemInfo(platformInfo: Purchases.PlatformInfo(flavor: "xyz", version: "1.2.3"),
                                         finishTransactions: true,
                                         storeKitVersion: .storeKit2,
                                         apiKeyValidationResult: .otherPlatforms)

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let expectation = XCTestExpectation(description: "Purchase completion")

        orchestrator.purchase(
            product: testProduct,
            package: nil,
            trackDiagnostics: false
        ) { _, _, error, _ in
            expect(error?.code) == ErrorCode.productNotAvailableForPurchaseError.rawValue
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertFalse(self.testStorePurchaseHandler.invokedPurchase.value)
    }

    func testPurchaseWithPackageContainingTestStoreProductAndTestAPIKeyCallsTestStorePurchaseHandler() async {
        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()
        let package = Package(
            identifier: "test_package",
            packageType: .monthly,
            storeProduct: testProduct,
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )

        let mockTransaction = Self.createMockTestStoreTransaction()
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .success(StoreTransaction(mockTransaction))

        let expectation = XCTestExpectation(description: "Purchase completion")

        orchestrator.purchase(
            product: testProduct,
            package: package,
            trackDiagnostics: false
        ) { _, _, _, _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertTrue(self.testStorePurchaseHandler.invokedPurchase.value)
        XCTAssertEqual(self.testStorePurchaseHandler.invokedPurchaseProduct.value?.productIdentifier, "test.product")
    }

    // MARK: - Purchase of Test Store Products

    func testSuccessfulPurchaseOfTestStoreProductReturnsCorrectValues() async throws {
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)
        let mockTransaction = Self.createMockTestStoreTransaction()
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .success(StoreTransaction(mockTransaction))

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertEqual(transaction?.testStoreTransaction, mockTransaction)
        XCTAssertFalse(userCancelled)
        XCTAssertNil(error)
        XCTAssertEqual(customerInfo, Self.mockCustomerInfo)
    }

    func testCancelledPurchaseOfTestStoreProductReturnsCorrectValues() async throws {
        self.customerInfoManager.stubbedCustomerInfoResult = .success(Self.mockCustomerInfo)
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .cancel

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertNil(transaction)
        XCTAssertTrue(userCancelled)
        XCTAssertEqual(error?.asErrorCode, ErrorCode.purchaseCancelledError)
        XCTAssertEqual(customerInfo, Self.mockCustomerInfo)
    }

    func testFailedPurchaseOfTestStoreProductReturnsCorrectValues() async throws {
        self.customerInfoManager.stubbedCustomerInfoResult = .success(Self.mockCustomerInfo)
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .failure(ErrorUtils.ineligibleError())

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertNil(transaction)
        XCTAssertFalse(userCancelled)
        XCTAssertEqual(error?.asErrorCode, ErrorCode.ineligibleError)
        XCTAssertEqual(customerInfo, Self.mockCustomerInfo)
    }

    func testSuccessfulPurchaseOfTestStoreProductPostsReceipt() async throws {
        self.backend.stubbedPostReceiptResult = .success(Self.mockCustomerInfo)
        let mockTransaction = Self.createMockTestStoreTransaction()
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .success(StoreTransaction(mockTransaction))

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertTrue(self.backend.invokedPostReceiptData)
        XCTAssertEqual(self.backend.invokedPostReceiptDataCount, 1)
        let transactionData = try XCTUnwrap(self.backend.invokedPostReceiptDataParameters?.transactionData)
        XCTAssertEqual(transactionData.appUserID, "appUserID")
        XCTAssertEqual(transactionData.storefront?.countryCode, Self.mockStorefront.countryCode)
    }

    func testCancelledPurchaseOfTestStoreProductDoesNotPostReceipt() async throws {
        self.customerInfoManager.stubbedCustomerInfoResult = .success(Self.mockCustomerInfo)
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .cancel

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertFalse(self.backend.invokedPostReceiptData)
    }

    func testFailedPurchaseOfTestStoreProductDoesNotPostReceipt() async throws {
        self.customerInfoManager.stubbedCustomerInfoResult = .success(Self.mockCustomerInfo)
        self.testStorePurchaseHandler.stubbedPurchaseResult.value = .failure(ErrorUtils.ineligibleError())

        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(
                product: testProduct,
                package: nil,
                trackDiagnostics: false) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        XCTAssertFalse(self.backend.invokedPostReceiptData)
    }

#endif

#if !TEST_STORE
    func testPurchaseWithTestStoreProductAndTestAPIKeyWhenTestStoreFlagDisabledReturnsError() async {
        let orchestrator = self.createOrchestrator()
        let testProduct = self.createTestStoreProduct()

        let expectation = XCTestExpectation(description: "Purchase completion")
        orchestrator.purchase(
            product: testProduct,
            package: nil,
            trackDiagnostics: false
        ) { _, _, error, _ in
            expect(error?.code) == ErrorCode.productNotAvailableForPurchaseError.rawValue
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)
    }
#endif

    private func createOrchestrator() -> PurchasesOrchestrator {
        let orchestrator = PurchasesOrchestrator(
            productsManager: self.productsManager,
            paymentQueueWrapper: .right(self.paymentQueueWrapper),
            testStorePurchaseHandler: self.testStorePurchaseHandler,
            systemInfo: self.systemInfo,
            subscriberAttributes: self.attribution,
            operationDispatcher: MockOperationDispatcher(),
            receiptFetcher: self.receiptFetcher,
            receiptParser: self.receiptParser,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.customerInfoManager,
            backend: self.backend,
            transactionPoster: self.transactionPoster,
            currentUserProvider: self.currentUserProvider,
            transactionsManager: self.transactionsManager,
            deviceCache: self.deviceCache,
            offeringsManager: self.mockOfferingsManager,
            manageSubscriptionsHelper: self.mockManageSubsHelper,
            beginRefundRequestHelper: self.mockBeginRefundRequestHelper,
            storeMessagesHelper: self.mockStoreMessagesHelper,
            diagnosticsTracker: self.diagnosticsTracker,
            winBackOfferEligibilityCalculator: self.mockWinBackOfferEligibilityCalculator,
            paywallEventsManager: self.paywallEventsManager,
            webPurchaseRedemptionHelper: self.webPurchaseRedemptionHelper,
            dateProvider: self.mockDateProvider
        )

        return orchestrator
    }

    private static let mockStorefront = MockStorefront(countryCode: "USA")

    private static func createMockTestStoreTransaction() -> TestStoreTransaction {
        return TestStoreTransaction(productIdentifier: "test_product_id",
                                    purchaseDate: self.eventTimestamp1,
                                    transactionIdentifier: "test_transaction_id",
                                    storefront: Storefront(mockStorefront),
                                    jwsRepresentation: nil)
    }

    private static var mockCustomerInfo: CustomerInfo { .emptyInfo }
}
