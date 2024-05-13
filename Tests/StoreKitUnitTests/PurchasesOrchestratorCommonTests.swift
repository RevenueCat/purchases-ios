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
            self.orchestrator.purchase(product: Self.testProduct, package: nil) { _, _, error, _ in
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
                promotionalOffer: offer
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

}
