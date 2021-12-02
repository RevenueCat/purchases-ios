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
    var receiptParser: MockReceiptParser!
    var deviceCache: MockDeviceCache!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!

    var orchestrator: PurchasesOrchestrator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpSystemInfo()
        productsManager = MockProductsManager(systemInfo: systemInfo)
        storeKitWrapper = MockStoreKitWrapper()
        operationDispatcher = MockOperationDispatcher()
        receiptFetcher = MockReceiptFetcher(requestFetcher: MockRequestFetcher(), systemInfo: systemInfo)
        deviceCache = MockDeviceCache(systemInfo: systemInfo)
        backend = MockBackend()
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: OperationDispatcher(),
                                                      deviceCache: deviceCache,
                                                      backend: backend,
                                                      systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        receiptParser = MockReceiptParser()
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
        mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: systemInfo)
        orchestrator = PurchasesOrchestrator(productsManager: productsManager,
                                             storeKitWrapper: storeKitWrapper,
                                             systemInfo: systemInfo,
                                             subscriberAttributesManager: subscriberAttributesManager,
                                             operationDispatcher: operationDispatcher,
                                             receiptFetcher: receiptFetcher,
                                             customerInfoManager: customerInfoManager,
                                             backend: backend,
                                             identityManager: identityManager,
                                             receiptParser: receiptParser,
                                             deviceCache: deviceCache,
                                             manageSubscriptionsHelper: mockManageSubsHelper,
                                             beginRefundRequestHelper: mockBeginRefundRequestHelper)
        setUpStoreKit2Listener()
    }

    fileprivate func setUpStoreKit2Listener() {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            orchestrator.storeKit2Listener = MockStoreKit2TransactionListener()
        }
    }

    fileprivate func setUpSystemInfo() throws {
        systemInfo = try MockSystemInfo(platformFlavor: "xyz",
                                        platformFlavorVersion: "1.2.3",
                                        finishTransactions: true)
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageReturnsCorrectValues() async throws {
        try checkForiOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let storeProduct = try await fetchSk2StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(transaction).to(beNil())
        expect(userCancelled) == false
        expect(error).to(beNil())

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

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageHandlesPurchaseResult() async throws {
        try checkForiOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let storeProduct = try await fetchSk2StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        let mockListener = try XCTUnwrap(orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener)
        expect(mockListener.invokedHandle) == true
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSendsReceiptToBackendIfSuccessful() async throws {
        try checkForiOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let storeProduct = try await fetchSk2StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        _ = await withCheckedContinuation { continuation in
            orchestrator.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(self.backend.invokedPostReceiptDataCount) == 1
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseSK2PackageSkipsIfPurchaseFailed() async throws {
        try checkForiOS15APIAvailableOrSkipTest()

        guard self.systemInfo.useStoreKit2IfAvailable else {
            throw XCTSkip("StoreKit 2 tests are disabled.")
        }

        testSession.failTransactionsEnabled = true
        customerInfoManager.stubbedCachedCustomerInfoResult = mockCustomerInfo
        backend.stubbedPostReceiptCustomerInfo = mockCustomerInfo

        let storeProduct = try await fetchSk2StoreProduct()
        let package = Package(identifier: "package",
                              packageType: .monthly,
                              storeProduct: storeProduct,
                              offeringIdentifier: "offering")

        let (transaction, customerInfo, error, userCancelled) = await withCheckedContinuation { continuation in
            orchestrator.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(returning: (transaction, customerInfo, error, userCancelled))
            }
        }

        expect(transaction).to(beNil())
        expect(userCancelled) == false
        expect(customerInfo).to(beNil())
        expect(error).toNot(beNil())
        expect(self.backend.invokedPostReceiptData) == false
        let mockListener = try XCTUnwrap(orchestrator.storeKit2Listener as? MockStoreKit2TransactionListener)
        expect(mockListener.invokedHandle) == false
    }

    func testShowManageSubscriptionsCallsCompletionWithErrorIfThereIsAFailure() {
        let message = "Failed to get managementURL from CustomerInfo. Details: customerInfo is nil."
        mockManageSubsHelper.mockError = ErrorUtils.customerInfoError(withMessage: message)
        var receivedError: Error?
        var completionCalled = false
        orchestrator.showManageSubscription { maybeError in
            completionCalled = true
            receivedError = maybeError
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        expect(receivedError).to(matchError(ErrorCode.customerInfoError))
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundRequestCallsCompletionWithoutErrorAndPassesThroughStatusIfSuccessful() {
        var receivedError: Error?
        var receivedStatus: RefundRequestStatus?
        var completionCalled = false
        let expectedStatus = RefundRequestStatus.userCancelled
        mockBeginRefundRequestHelper.maybeMockRefundRequestStatus = expectedStatus

        orchestrator.beginRefundRequest(for: "1234") { status, maybeError in
            completionCalled = true
            receivedError = maybeError
            receivedStatus = status
        }

        expect(receivedStatus) == expectedStatus
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func testBeginRefundRequestCallsCompletionWithErrorIfThereIsAFailure() {
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        mockBeginRefundRequestHelper.maybeMockError = expectedError

        var receivedError: Error?
        var completionCalled = false
        var receivedStatus: RefundRequestStatus?

        orchestrator.beginRefundRequest(for: "1235") { status, maybeError in
            completionCalled = true
            receivedError = maybeError
            receivedStatus = status
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        expect(receivedStatus) == RefundRequestStatus.error
        expect(receivedError).to(matchError(expectedError))
    }

}

private extension PurchasesOrchestratorTests {

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func fetchSk2Product() async throws -> SK2Product {
        let products: [Any] = try await StoreKit.Product.products(for: ["com.revenuecat.monthly_4.99.1_week_intro"])
        let firstProduct = try XCTUnwrap(products.first)
        return try XCTUnwrap(firstProduct as? SK2Product)
    }

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func fetchSk2StoreProduct() async throws -> SK2StoreProduct {
        // can't store Storekit.Product directly because it causes linking issues on OS versions
        // older than iOS 15.0 (and equivalent)
        // https://openradar.appspot.com/radar?id=4970535809187840
        let sk2Product: Any = try await fetchSk2Product()
        return SK2StoreProduct(sk2Product: try XCTUnwrap(sk2Product as? SK2Product))
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
