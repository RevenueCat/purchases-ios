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

class PurchasesOrchestratorTests: StoreKitConfigTestCase {

    var productsManager: MockProductsManager!
    var storeKitWrapper: MockStoreKitWrapper!
    var systemInfo: MockSystemInfo!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var operationDispatcher: MockOperationDispatcher!
    var receiptFetcher: MockReceiptFetcher!
    var customerInfoManager: MockCustomerInfoManager!
    var backend: MockBackend!
    var identityManager: MockIdentityManager!
    var transactionsManager: MockTransactionsManager!
    var deviceCache: MockDeviceCache!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!

    var orchestrator: PurchasesOrchestrator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpSystemInfo()
        productsManager = MockProductsManager(systemInfo: systemInfo)
        operationDispatcher = MockOperationDispatcher()
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: systemInfo)
        deviceCache = MockDeviceCache(systemInfo: systemInfo)
        backend = MockBackend()
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: OperationDispatcher(),
                                                      deviceCache: deviceCache,
                                                      backend: backend,
                                                      systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        transactionsManager = MockTransactionsManager(receiptParser: MockReceiptParser())
        let attributionFetcher = MockAttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                        systemInfo: systemInfo)
        subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: backend,
            deviceCache: deviceCache,
            attributionFetcher: attributionFetcher,
            attributionDataMigrator: MockAttributionDataMigrator())
        mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: systemInfo,
                                                             customerInfoManager: customerInfoManager,
                                                             identityManager: identityManager)
        mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: systemInfo,
                                                                    customerInfoManager: customerInfoManager,
                                                                    identityManager: identityManager)
        setupStoreKitWrapper()
        setUpOrchestrator()
        setUpStoreKit2Listener()
    }

    fileprivate func setUpStoreKit2Listener() {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            orchestrator.storeKit2Listener = MockStoreKit2TransactionListener()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var mockStoreKit2TransactionListener: MockStoreKit2TransactionListener? {
        return orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener
    }

    fileprivate func setUpSystemInfo(finishTransactions: Bool = true) throws {
        systemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                        platformFlavorVersion: "1.2.3",
                                        finishTransactions: finishTransactions)
    }

    fileprivate func setupStoreKitWrapper() {
        storeKitWrapper = MockStoreKitWrapper()
        storeKitWrapper.mockAddPaymentTransactionState = .purchased
        storeKitWrapper.mockCallUpdatedTransactionInstantly = true
    }

    fileprivate func setUpOrchestrator() {
        orchestrator = PurchasesOrchestrator(productsManager: productsManager,
                                             storeKitWrapper: storeKitWrapper,
                                             systemInfo: systemInfo,
                                             subscriberAttributesManager: subscriberAttributesManager,
                                             operationDispatcher: operationDispatcher,
                                             receiptFetcher: receiptFetcher,
                                             customerInfoManager: customerInfoManager,
                                             backend: backend,
                                             identityManager: identityManager,
                                             transactionsManager: transactionsManager,
                                             deviceCache: deviceCache,
                                             manageSubscriptionsHelper: mockManageSubsHelper,
                                             beginRefundRequestHelper: mockBeginRefundRequestHelper)
        storeKitWrapper.delegate = orchestrator
    }

    func testPurchaseSK1PackageSendsReceiptToBackendIfSuccessful() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let product = try await fetchSk1Product()
        let storeProduct = try await fetchSk1StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let payment = storeKitWrapper.payment(withProduct: product)

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  payment: payment,
                                  package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
    }

    func testPurchaseSK1PromotionalOffer() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo
        backend.stubbedPostOfferCompetionResult = ("signature", "identifier", UUID(), 12345, nil)

        let product = try await fetchSk1Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            price: 11.1,
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month))

        _ = await withCheckedContinuation { continuation in
            orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                          product: StoreProduct(sk1Product: product)) { paymentDiscount, error in
                continuation.resume(returning: (paymentDiscount, error))
            }
        }

        expect(self.backend.invokedPostOfferCount) == 1
        expect(self.backend.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
    }

    func testPurchaseSK1PackageWithDiscountSendsReceiptToBackendIfSuccessful() async throws {
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostOfferCompetionResult = ("signature", "identifier", UUID(), 12345, nil)
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let product = try await fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            price: 11.1,
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month))

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(sk1Product: product,
                                  discount: storeProductDiscount,
                                  package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCorrectValues() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let mockTransaction = try await createTransactionWithPurchase()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo
        mockStoreKit2TransactionListener?.mockTransaction = .init(mockTransaction)

        let product = try await self.fetchSk2Product()

        let (transaction, customerInfo, userCancelled) = try await orchestrator.purchase(sk2Product: product,
                                                                                         discount: nil)

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
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

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

        let mockListener = try XCTUnwrap(orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener)
        expect(mockListener.invokedHandle) == true
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let product = try await fetchSk2Product()

        _ = try await orchestrator.purchase(sk2Product: product, discount: nil)

        expect(self.backend.invokedPostReceiptDataCount) == 1
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSkipsIfPurchaseFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        testSession.failTransactionsEnabled = true
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let product = try await fetchSk2Product()
        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            price: 11.1,
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month))

        do {
            _ = try await orchestrator.purchase(sk2Product: product, discount: storeProductDiscount)
            XCTFail("Expected error")
        } catch {
            expect(self.backend.invokedPostReceiptData) == false
            let mockListener = try XCTUnwrap(orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener)
            expect(mockListener.invokedHandle) == false
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsMissingReceiptErrorIfSendReceiptFailed() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        receiptFetcher.shouldReturnReceipt = false
        let expectedError = ErrorUtils.missingReceiptFileError()

        let product = try await fetchSk2Product()

        do {
            _ = try await orchestrator.purchase(sk2Product: product, discount: nil)

            XCTFail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))

            let mockListener = try XCTUnwrap(orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener)
            expect(mockListener.invokedHandle) == true
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testStoreKit2TransactionListenerDelegate() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo

        orchestrator.transactionsUpdated()

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.isRestore).to(beFalse())
    }

    func testStoreKit2TransactionListenerDelegateWithObserverMode() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try setUpSystemInfo(finishTransactions: false)
        setUpOrchestrator()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo

        orchestrator.transactionsUpdated()

        expect(self.backend.invokedPostReceiptData).to(beTrue())
        expect(self.backend.invokedPostReceiptDataParameters?.isRestore).to(beTrue())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo
        backend.stubbedPostOfferCompetionResult = ("signature", "identifier", UUID(), 12345, nil)

        let product = try await fetchSk2Product()

        let storeProductDiscount = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                            price: 11.1,
                                                            paymentMode: .payAsYouGo,
                                                            subscriptionPeriod: .init(value: 1, unit: .month))

        _ = try await orchestrator.promotionalOffer(forProductDiscount: storeProductDiscount,
                                                    product: StoreProduct(sk2Product: product))

        expect(self.backend.invokedPostOfferCount) == 1
        expect(self.backend.invokedPostOfferParameters?.offerIdentifier) == storeProductDiscount.offerIdentifier
    }

    func testShowManageSubscriptionsCallsCompletionWithErrorIfThereIsAFailure() {
        let message = "Failed to get managementURL from CustomerInfo. Details: customerInfo is nil."
        mockManageSubsHelper.mockError = ErrorUtils.customerInfoError(withMessage: message)
        var receivedError: Error?
        var completionCalled = false
        orchestrator.showManageSubscription { error in
            completionCalled = true
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
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

}

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
