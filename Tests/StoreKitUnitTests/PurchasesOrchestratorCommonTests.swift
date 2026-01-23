//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestratorCommonTests.swift
//
//  Created by Mark Villacampa on 16/2/24.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class PurchasesOrchestratorCommonTests: BasePurchasesOrchestratorTests {

    // MARK: - TestStoreProduct

    func testPurchasingTestProductFails() async throws {
        let error = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: Self.testProduct,
                                       package: nil,
                                       trackDiagnostics: false) { _, _, error, _ in
                continuation.resume(returning: error)
            }
        }
        expect(error).to(matchError(ErrorCode.productNotAvailableForPurchaseError))
    }

    func testPurchasingTestProductWithPromotionalOfferFails() async throws {
        let offer = PromotionalOffer.SignedData(identifier: "",
                                                keyIdentifier: "",
                                                nonce: UUID(),
                                                signature: "",
                                                timestamp: 0)

        let error = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(
                product: Self.testProduct,
                package: nil,
                promotionalOffer: offer,
                trackDiagnostics: false
            ) { _, _, error, _ in
                continuation.resume(returning: error)
            }
        }
        expect(error).to(matchError(ErrorCode.productNotAvailableForPurchaseError))
    }

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    // MARK: - showManageSubscription

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

    // MARK: - RefundRequest

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

    // MARK: - allowSharingAppStoreAccount

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsNotDefined() async throws {
        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasNotLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false
        )
    }

    func testRestorePurchasesDoesNotLogWarningIfAllowSharingAppStoreAccountIsTrue() async throws {
        self.orchestrator.allowSharingAppStoreAccount = true

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasNotLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false
        )
    }

    func testRestorePurchasesLogsWarningIfAllowSharingAppStoreAccountIsFalse() async throws {
        self.orchestrator.allowSharingAppStoreAccount = false

        self.customerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo

        _ = try? await self.orchestrator.syncPurchases(receiptRefreshPolicy: .never,
                                                       isRestore: false,
                                                       initiationSource: .restore)

        self.logger.verifyMessageWasLogged(
            Strings
                .purchase
                .restorepurchases_called_with_allow_sharing_appstore_account_false,
            level: .warn
        )
    }

    // MARK: - Diagnostics
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testSyncingDiagnosticsOnInitialization() throws {
        let mockDiagnosticsSynchronizer = MockDiagnosticsSynchronizer()
        let transactionListener = MockStoreKit2TransactionListener()
        let storeKit2ObserverModePurchaseDetector = MockStoreKit2ObserverModePurchaseDetector()

        self.setUpOrchestrator(storeKit2TransactionListener: transactionListener,
                               storeKit2StorefrontListener: StoreKit2StorefrontListener(delegate: nil),
                               storeKit2ObserverModePurchaseDetector: storeKit2ObserverModePurchaseDetector,
                               diagnosticsSynchronizer: mockDiagnosticsSynchronizer)
        expect(self.orchestrator.diagnosticsSynchronizer).toNot(beNil())
        expect(mockDiagnosticsSynchronizer.invokedSyncDiagnosticsIfNeeded).toEventually(beTrue())
    }

    // MARK: - Web purchase redemption

    func testRedeemWebPurchaseWiresResultAppropriately() async {
        self.setUpOrchestrator()

        self.webPurchaseRedemptionHelper.stubbedHandleRedeemWebPurchaseResult = .purchaseBelongsToOtherUser

        var expectedResultCalled = false
        let result = await self.orchestrator.redeemWebPurchase(.init(redemptionToken: "test-redemption-token"))
        switch result {
        case .purchaseBelongsToOtherUser:
            expectedResultCalled = true
        default:
            XCTFail("Unexpected result: \(result)")
        }

        expect(expectedResultCalled) == true
    }

    // MARK: - syncRemainingCachedTransactionMetadataIfNeeded (Cached Transaction Metadata Sync)

    func testSyncRemainingCachedTransactionMetadataDoesNothingWhenNoCachedMetadata() {
        // No metadata stored - should not call backend
        expect(self.mockLocalTransactionMetadataStore.getAllStoredMetadata()).to(beEmpty())

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        expect(self.operationDispatcher.invokedDispatchOnWorkerThread) == true
        expect(self.backend.invokedPostReceiptData) == false
    }

    func testSyncRemainingCachedTransactionMetadataPostsCachedMetadata() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.backend.invokedPostReceiptData).toEventually(beTrue())
        await expect(self.backend.invokedPostReceiptDataParameters?.productData?.productIdentifier)
            .toEventually(equal("product_1"))
        await expect(self.backend.invokedPostReceiptDataParameters?.associatedTransactionId)
            .toEventually(equal(transactionId))
    }

    func testSyncRemainingCachedTransactionMetadataCachesCustomerInfoOnSuccess() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.customerInfoManager.invokedCacheCustomerInfo).toEventually(beTrue())
        await expect(self.customerInfoManager.invokedCacheCustomerInfoParameters?.info)
            .toEventually(beIdenticalTo(self.mockCustomerInfo))
    }

    func testSyncRemainingCachedTransactionMetadataRemovesMetadataOnSuccess() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.mockLocalTransactionMetadataStore.invokedRemoveMetadata.value).toEventually(beTrue())
        await expect(self.mockLocalTransactionMetadataStore.invokedRemoveMetadataTransactionId.value)
            .toEventually(equal(transactionId))
    }

    func testSyncRemainingCachedTransactionMetadataPostsMultipleEntries() async {
        let transactionId1 = "cached_transaction_1"
        let transactionId2 = "cached_transaction_2"
        let metadata1 = self.createCachedMetadata(transactionId: transactionId1, productIdentifier: "product_1")
        let metadata2 = self.createCachedMetadata(transactionId: transactionId2, productIdentifier: "product_2")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.mockLocalTransactionMetadataStore.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.backend.invokedPostReceiptDataCount).toEventually(equal(2))
    }

    func testSyncRemainingCachedTransactionMetadataUsesCurrentAppUserID() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.backend.invokedPostReceiptDataParameters?.appUserID).toEventually(equal(Self.mockUserID))
    }

    func testSyncRemainingCachedTransactionMetadataUsesQueueInitiationSource() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        await expect(self.backend.invokedPostReceiptDataParameters?.postReceiptSource.initiationSource)
            .toEventually(equal(.queue))
    }

    func testSyncRemainingCachedTransactionMetadataDoesNotCacheCustomerInfoOnFailure() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)

        // Create a non-finishable error
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let nonFinishableError = BackendError.networkError(.networkError(networkError))
        self.backend.stubbedPostReceiptResult = .failure(nonFinishableError)

        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        // Wait for the backend to be invoked (meaning the async work completed)
        await expect(self.backend.invokedPostReceiptData).toEventually(beTrue())
        // Then verify customer info was NOT cached
        expect(self.customerInfoManager.invokedCacheCustomerInfo) == false
    }

    func testSyncRemainingCachedTransactionMetadataPreventsConcurrentSyncs() async {
        let transactionId = "cached_transaction_1"
        let metadata = self.createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.stubbedPostReceiptResult = .success(self.mockCustomerInfo)

        // Call syncRemainingCachedTransactionMetadataIfNeeded multiple times rapidly
        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()
        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()
        self.orchestrator.syncRemainingCachedTransactionMetadataIfNeeded()

        // Wait for the backend to be invoked
        await expect(self.backend.invokedPostReceiptData).toEventually(beTrue())

        // Wait a bit more to ensure any duplicate calls would have completed
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Should only have gotten cached metadata once and posted receipt once
        expect(self.mockLocalTransactionMetadataStore.invokedGetAllStoredMetadataCount.value) == 1
        expect(self.backend.invokedPostReceiptDataCount) == 1
    }

    // MARK: - Helper methods

    private func createCachedMetadata(
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

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasesOrchestratorTrackingTests: BasePurchasesOrchestratorTests {

    private func getMockDiagnosticsTracker() throws -> MockDiagnosticsTracker {
        return try XCTUnwrap(self.mockDiagnosticsTracker as? MockDiagnosticsTracker)
    }

    // MARK: - Purchase Product events

    func testTracksPurchaseSK1ProductSuccessWhenEnabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: true) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(haveCount(1))
        let startedParams = mockDiagnosticsTracker.trackedPurchasesStartedParams.value[0]
        expect(startedParams.productId) == storeProduct.productIdentifier
        expect(startedParams.productType) == storeProduct.productType

        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(haveCount(1))
        let resultParams = mockDiagnosticsTracker.trackedPurchasesResultParams.value[0]
        expect(resultParams.productId) == storeProduct.productIdentifier
        expect(resultParams.productType) == storeProduct.productType
        expect(resultParams.verificationResult) == mockCustomerInfo.entitlements.verification
        expect(resultParams.errorMessage) == nil
        expect(resultParams.errorCode) == nil
    }

    func testTracksPurchaseSK1ProductFailureWhenEnabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )
        self.backend.stubbedPostReceiptResult = .failure(stubbedError)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: true) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(haveCount(1))
        let startedParams = try XCTUnwrap(mockDiagnosticsTracker.trackedPurchasesStartedParams.value.first)
        expect(startedParams.productId) == storeProduct.productIdentifier
        expect(startedParams.productType) == storeProduct.productType

        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(haveCount(1))
        let resultParams = try XCTUnwrap(mockDiagnosticsTracker.trackedPurchasesResultParams.value.first)
        expect(resultParams.productId) == storeProduct.productIdentifier
        expect(resultParams.productType) == storeProduct.productType
        expect(resultParams.verificationResult).to(beNil())
        expect(resultParams.errorMessage) == stubbedError.asPurchasesError.localizedDescription
        expect(resultParams.errorCode) == stubbedError.asPublicError.code
    }

    func testDoesNotTrackPurchaseSK1ProductSuccessWhenDisabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: false) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(beEmpty())
        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(beEmpty())
    }

    func testDoesNotTrackPurchaseSK1ProductFailureWhenDisabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )
        self.backend.stubbedPostReceiptResult = .failure(stubbedError)

        let product = try await self.fetchSk1Product()
        let storeProduct = StoreProduct(sk1Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: false) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(beEmpty())
        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(beEmpty())
    }

    func testTracksPurchaseSK2ProductSuccessWhenEnabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.operationDispatcher.forwardToOriginalDispatchOnWorkerThread = true

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: true) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(haveCount(1))
        let startedParams = mockDiagnosticsTracker.trackedPurchasesStartedParams.value[0]
        expect(startedParams.productId) == storeProduct.productIdentifier
        expect(startedParams.productType) == storeProduct.productType

        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(haveCount(1))
        let resultParams = mockDiagnosticsTracker.trackedPurchasesResultParams.value[0]
        expect(resultParams.productId) == storeProduct.productIdentifier
        expect(resultParams.productType) == storeProduct.productType
        expect(resultParams.verificationResult) == mockCustomerInfo.entitlements.verification
        expect(resultParams.errorMessage) == nil
        expect(resultParams.errorCode) == nil
    }

    func testTracksPurchaseSK2ProductFailureWhenEnabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )
        self.backend.stubbedPostReceiptResult = .failure(stubbedError)

        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: true) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(haveCount(1))
        let startedParams = try XCTUnwrap(mockDiagnosticsTracker.trackedPurchasesStartedParams.value.first)
        expect(startedParams.productId) == storeProduct.productIdentifier
        expect(startedParams.productType) == storeProduct.productType

        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(haveCount(1))
        let resultParams = try XCTUnwrap(mockDiagnosticsTracker.trackedPurchasesResultParams.value.first)
        expect(resultParams.productId) == storeProduct.productIdentifier
        expect(resultParams.productType) == storeProduct.productType
        expect(resultParams.verificationResult).to(beNil())
        expect(resultParams.errorMessage) == stubbedError.asPurchasesError.localizedDescription
        expect(resultParams.errorCode) == stubbedError.asPublicError.code
    }

    func testDoesNotTrackPurchaseSK2ProductSuccessWhenDisabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.operationDispatcher.forwardToOriginalDispatchOnWorkerThread = true

        self.backend.stubbedPostReceiptResult = .success(mockCustomerInfo)

        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: false) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(beEmpty())
        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(beEmpty())
    }

    func testDoesNotTrackPurchaseSK2ProductFailureWhenDisabledDiagnostics() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )
        self.backend.stubbedPostReceiptResult = .failure(stubbedError)

        let product = try await self.fetchSk2Product()
        let storeProduct = StoreProduct(sk2Product: product)

        _ = await withCheckedContinuation { continuation in
            self.orchestrator.purchase(product: storeProduct,
                                       package: nil,
                                       trackDiagnostics: false) { _, _, _, _ in
                continuation.resume()
            }
        }

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchasesStartedParams.value).to(beEmpty())
        expect(mockDiagnosticsTracker.trackedPurchasesResultParams.value).to(beEmpty())
    }

}

#if compiler(>=5.10) && !os(tvOS) && !os(watchOS) && !os(visionOS)

// MARK: - Purchase Intent Received events

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
final class MockStoreKit2PurchaseIntent: StoreKit2PurchaseIntentType {

    let product: StoreKit.Product
    let offer: StoreKit.Product.SubscriptionOffer? = nil
    let id: StoreKit.Product.ID

    init(product: StoreKit.Product, id: StoreKit.Product.ID) {
        self.product = product
        self.id = id
    }

    static func == (lhs: MockStoreKit2PurchaseIntent, rhs: MockStoreKit2PurchaseIntent) -> Bool {
        lhs.product == rhs.product && lhs.id == rhs.id
    }

}

@available(iOS 16.4, macOS 14.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension PurchasesOrchestratorTrackingTests {

    func testTracksPurchaseIntentReceived() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let sk2Product = try await self.fetchSk2Product()
        let storePurchaseIntent = StorePurchaseIntent(purchaseIntent: MockStoreKit2PurchaseIntent(product: sk2Product,
                                                                                                  id: sk2Product.id))
        await self.orchestrator.storeKit2PurchaseIntentListener(MockStoreKit2PurchaseIntentListener(),
                                                                purchaseIntent: storePurchaseIntent)

        let mockDiagnosticsTracker = try getMockDiagnosticsTracker()

        expect(mockDiagnosticsTracker.trackedPurchaseIntentReceivedParams.value.count) == 1
        let params = mockDiagnosticsTracker.trackedPurchaseIntentReceivedParams.value[0]
        expect(params.productId) == sk2Product.id
        expect(params.offerId) == nil
        expect(params.offerType) == nil
    }

}

#endif
