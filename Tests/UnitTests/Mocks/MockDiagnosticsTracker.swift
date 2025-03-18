//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockDiagnosticsTracker.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class MockDiagnosticsTracker: DiagnosticsTrackerType, Sendable {

    let trackedEvents: Atomic<[DiagnosticsEvent]> = .init([])
    let trackedCustomerInfo: Atomic<[CustomerInfo]> = .init([])

    func track(_ event: DiagnosticsEvent) {
        self.trackedEvents.modify { $0.append(event) }
    }

    func trackCustomerInfoVerificationResultIfNeeded(
        _ customerInfo: RevenueCat.CustomerInfo
    ) {
        self.trackedCustomerInfo.modify { $0.append(customerInfo) }
    }

    let trackedHttpRequestPerformedParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (String, TimeInterval, Bool, Int, Int?, HTTPResponseOrigin?, VerificationResult, Bool)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult,
                                   isRetry: Bool) {
        self.trackedHttpRequestPerformedParams.modify {
            $0.append(
                (endpointName,
                 responseTime,
                 wasSuccessful,
                 responseCode,
                 backendErrorCode,
                 resultOrigin,
                 verificationResult,
                 isRetry)
            )
        }
    }

    let trackedPurchaseRequestParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (wasSuccessful: Bool,
         storeKitVersion: StoreKitVersion,
         errorMessage: String?,
         errorCode: Int?,
         storeKitErrorDescription: String?,
         productId: String,
         promotionalOfferId: String?,
         winBackOfferApplied: Bool,
         purchaseResult: DiagnosticsEvent.PurchaseResult?,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackPurchaseRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              productId: String,
                              promotionalOfferId: String?,
                              winBackOfferApplied: Bool,
                              purchaseResult: DiagnosticsEvent.PurchaseResult?,
                              responseTime: TimeInterval) {
        self.trackedPurchaseRequestParams.modify {
            $0.append(
                (wasSuccessful,
                 storeKitVersion,
                 errorMessage,
                 errorCode,
                 storeKitErrorDescription,
                 productId,
                 promotionalOfferId,
                 winBackOfferApplied,
                 purchaseResult,
                 responseTime)
            )
        }
    }

    let trackedProductsRequestParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (wasSuccessful: Bool,
         storeKitVersion: StoreKitVersion,
         errorMessage: String?,
         errorCode: Int?,
         storeKitErrorDescription: String?,
         requestedProductIds: Set<String>,
         notFoundProductIds: Set<String>,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackProductsRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              requestedProductIds: Set<String>,
                              notFoundProductIds: Set<String>,
                              responseTime: TimeInterval) {
        self.trackedProductsRequestParams.modify {
            $0.append(
                (wasSuccessful,
                 storeKitVersion,
                 errorMessage,
                 errorCode,
                 storeKitErrorDescription,
                 requestedProductIds,
                 notFoundProductIds,
                 responseTime)
            )
        }
    }

    let trackedMaxDiagnosticsSyncRetriesReachedCalls: Atomic<Int> = .init(0)
    func trackMaxDiagnosticsSyncRetriesReached() {
        trackedMaxDiagnosticsSyncRetriesReachedCalls.modify { $0 += 1 }
    }

    let trackedClearingDiagnosticsAfterFailedSyncCalls: Atomic<Int> = .init(0)
    func trackClearingDiagnosticsAfterFailedSync() {
        trackedClearingDiagnosticsAfterFailedSyncCalls.modify { $0 += 1 }
    }

    let trackedEnteredOfflineEntitlementsModeCalls: Atomic<Int> = .init(0)
    func trackEnteredOfflineEntitlementsMode() {
        trackedEnteredOfflineEntitlementsModeCalls.modify { $0 += 1 }
    }

    let trackedErrorEnteringOfflineEntitlementsModeCalls: Atomic<[
        (DiagnosticsEvent.OfflineEntitlementsModeErrorReason, String)]> = .init([])
    func trackErrorEnteringOfflineEntitlementsMode(reason: DiagnosticsEvent.OfflineEntitlementsModeErrorReason,
                                                   errorMessage: String) {
        self.trackedErrorEnteringOfflineEntitlementsModeCalls.modify {
            $0.append(
                (reason,
                 errorMessage)
            )
        }
    }

    let trackedOfferingsStartedCount: Atomic<Int> = .init(0)
    func trackOfferingsStarted() {
        self.trackedOfferingsStartedCount.modify { $0 += 1 }
    }

    let trackedOfferingsResultParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (requestedProductIds: Set<String>?,
         notFoundProductIds: Set<String>?,
         errorMessage: String?,
         errorCode: Int?,
         verificationResult: VerificationResult?,
         cacheStatus: CacheStatus,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackOfferingsResult(requestedProductIds: Set<String>?,
                              notFoundProductIds: Set<String>?,
                              errorMessage: String?,
                              errorCode: Int?,
                              verificationResult: VerificationResult?,
                              cacheStatus: CacheStatus,
                              responseTime: TimeInterval) {
        self.trackedOfferingsResultParams.modify {
            $0.append(
                (requestedProductIds,
                 notFoundProductIds,
                 errorMessage,
                 errorCode,
                 verificationResult,
                 cacheStatus,
                 responseTime)
            )
        }
    }

    let trackedProductsStartedParams: Atomic<[
        Set<String>
    ]> = .init([])
    func trackProductsStarted(requestedProductIds: Set<String>) {
        self.trackedProductsStartedParams.modify {
            $0.append(requestedProductIds)
        }
    }

    let trackedProductsResultParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (requestedProductIds: Set<String>?,
         notFoundProductIds: Set<String>?,
         errorMessage: String?,
         errorCode: Int?,
         responseTime: TimeInterval)
    ]> = .init([])
    func trackProductsResult(requestedProductIds: Set<String>,
                             notFoundProductIds: Set<String>?,
                             errorMessage: String?,
                             errorCode: Int?,
                             responseTime: TimeInterval) {
        self.trackedProductsResultParams.modify {
            $0.append(
                (requestedProductIds, notFoundProductIds, errorMessage, errorCode, responseTime)
            )
        }
    }

    let trackedGetCustomerInfoStartedCalls: Atomic<Int> = .init(0)
    func trackGetCustomerInfoStarted() {
        trackedGetCustomerInfoStartedCalls.modify { $0 += 1 }
    }

    let trackedGetCustomerInfoResultParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (cacheFetchPolicy: RevenueCat.CacheFetchPolicy,
         verificationResult: RevenueCat.VerificationResult?,
         hadUnsyncedPurchasesBefore: Bool?,
         errorMessage: String?,
         errorCode: Int?,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackGetCustomerInfoResult(cacheFetchPolicy: RevenueCat.CacheFetchPolicy,
                                    verificationResult: RevenueCat.VerificationResult?,
                                    hadUnsyncedPurchasesBefore: Bool?,
                                    errorMessage: String?,
                                    errorCode: Int?,
                                    responseTime: TimeInterval) {
        self.trackedGetCustomerInfoResultParams.modify {
            $0.append(
                (cacheFetchPolicy,
                 verificationResult,
                 hadUnsyncedPurchasesBefore,
                 errorMessage,
                 errorCode,
                 responseTime
                )
            )
        }
    }

    let trackedSyncPurchasesStartedCalls: Atomic<Int> = .init(0)
    func trackSyncPurchasesStarted() {
        self.trackedSyncPurchasesStartedCalls.modify { $0 += 1 }
    }

    let trackedSyncPurchasesResultParams: Atomic<[
        (errorMessage: String?,
         errorCode: Int?,
         responseTime: TimeInterval)
    ]> = .init([])
    func trackSyncPurchasesResult(errorMessage: String?,
                                  errorCode: Int?,
                                  responseTime: TimeInterval) {
        self.trackedSyncPurchasesResultParams.modify {
            $0.append((errorMessage, errorCode, responseTime))
        }
    }

    let trackedRestorePurchasesStartedCalls: Atomic<Int> = .init(0)
    func trackRestorePurchasesStarted() {
        self.trackedRestorePurchasesStartedCalls.modify { $0 += 1 }
    }

    let trackedRestorePurchasesResultParams: Atomic<[
        (errorMessage: String?,
         errorCode: Int?,
         responseTime: TimeInterval)
    ]> = .init([])
    func trackRestorePurchasesResult(errorMessage: String?,
                                     errorCode: Int?,
                                     responseTime: TimeInterval) {
        self.trackedRestorePurchasesResultParams.modify {
            $0.append((errorMessage, errorCode, responseTime))
        }
    }

    let trackedApplePresentCodeRedemptionSheetRequestCalls: Atomic<Int> = .init(0)
    func trackApplePresentCodeRedemptionSheetRequest() {
        self.trackedApplePresentCodeRedemptionSheetRequestCalls.modify { $0 += 1 }
    }

    let trackedAppleTrialOrIntroEligibilityRequestParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (storeKitVersion: StoreKitVersion,
         requestedProductIds: Set<String>,
         eligibilityUnknownCount: Int?,
         eligibilityIneligibleCount: Int?,
         eligibilityEligibleCount: Int?,
         eligibilityNoIntroOfferCount: Int?,
         errorMessage: String?,
         errorCode: Int?,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackAppleTrialOrIntroEligibilityRequest(storeKitVersion: StoreKitVersion,
                                                  requestedProductIds: Set<String>,
                                                  eligibilityUnknownCount: Int?,
                                                  eligibilityIneligibleCount: Int?,
                                                  eligibilityEligibleCount: Int?,
                                                  eligibilityNoIntroOfferCount: Int?,
                                                  errorMessage: String?,
                                                  errorCode: Int?,
                                                  responseTime: TimeInterval) {
        self.trackedAppleTrialOrIntroEligibilityRequestParams.modify {
            $0.append((storeKitVersion,
                       requestedProductIds,
                       eligibilityUnknownCount,
                       eligibilityIneligibleCount,
                       eligibilityEligibleCount,
                       eligibilityNoIntroOfferCount,
                       errorMessage,
                       errorCode,
                       responseTime))
        }
    }

    let trackedAppleTransactionQueueReceivedParams: Atomic<[
        (productId: String?,
         paymentDiscountId: String?,
         transactionState: String,
         errorMessage: String?)
    ]> = .init([])
    func trackAppleTransactionQueueReceived(productId: String?,
                                            paymentDiscountId: String?,
                                            transactionState: String,
                                            errorMessage: String?) {
        self.trackedAppleTransactionQueueReceivedParams.modify {
            $0.append((productId, paymentDiscountId, transactionState, errorMessage))
        }
    }

}
