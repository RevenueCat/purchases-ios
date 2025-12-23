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

    // swiftlint:disable large_tuple
    // swiftlint:disable line_length
    let trackedHttpRequestPerformedParams: Atomic<[
        (String, String?, TimeInterval, Bool, Int, Int?, HTTPResponseOrigin?, VerificationResult, Bool, ConnectionErrorReason?)
    ]> = .init([])
    // swiftlint:enable large_tuple
    // swiftlint:enable line_length

    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   host: String?,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult,
                                   isRetry: Bool,
                                   connectionErrorReason: ConnectionErrorReason? = nil) {
        self.trackedHttpRequestPerformedParams.modify {
            $0.append(
                (endpointName,
                 host,
                 responseTime,
                 wasSuccessful,
                 responseCode,
                 backendErrorCode,
                 resultOrigin,
                 verificationResult,
                 isRetry,
                 connectionErrorReason)
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
         storefront: String?,
         productId: String,
         promotionalOfferId: String?,
         winBackOfferApplied: Bool,
         purchaseResult: DiagnosticsEvent.PurchaseResult?,
         responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackPurchaseAttempt(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              storefront: String?,
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
                 storefront,
                 productId,
                 promotionalOfferId,
                 winBackOfferApplied,
                 purchaseResult,
                 responseTime)
            )
        }
    }

    let trackedPurchaseIntentReceivedParams: Atomic<[
        (productId: String,
         offerId: String?,
         offerType: String?)
    ]> = .init([])
    func trackPurchaseIntentReceived(productId: String,
                                     offerId: String?,
                                     offerType: String?) {
        self.trackedPurchaseIntentReceivedParams.modify {
            $0.append((productId, offerId, offerType))
        }
    }

    let trackedProductsRequestParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (wasSuccessful: Bool,
         storeKitVersion: StoreKitVersion,
         errorMessage: String?,
         errorCode: Int?,
         storeKitErrorDescription: String?,
         storefront: String?,
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
                              storefront: String?,
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
                 storefront,
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

    let trackedPurchasesStartedParams: Atomic<[
        (productId: String?,
         productType: StoreProduct.ProductType?)
    ]> = .init([])
    func trackPurchaseStarted(productId: String,
                              productType: StoreProduct.ProductType) {
        self.trackedPurchasesStartedParams.modify {
            $0.append((productId, productType))
        }
    }

    let trackedPurchasesResultParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (productId: String,
         productType: StoreProduct.ProductType,
         verificationResult: VerificationResult?,
         errorMessage: String?,
         errorCode: Int?,
        responseTime: TimeInterval)
    ]> = .init([])
    // swiftlint:disable:next function_parameter_count
    func trackPurchaseResult(productId: String,
                             productType: StoreProduct.ProductType,
                             verificationResult: VerificationResult?,
                             errorMessage: String?,
                             errorCode: Int?,
                             responseTime: TimeInterval) {
        self.trackedPurchasesResultParams.modify {
            $0.append((productId, productType, verificationResult, errorMessage, errorCode, responseTime))
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
         storefront: String?,
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
                                                  storefront: String?,
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
                       storefront,
                       responseTime))
        }
    }

    let trackedAppleTransactionQueueReceivedParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (productId: String?,
         paymentDiscountId: String?,
         transactionState: String,
         storefront: String?,
         errorMessage: String?)
    ]> = .init([])
    func trackAppleTransactionQueueReceived(productId: String?,
                                            paymentDiscountId: String?,
                                            transactionState: String,
                                            storefront: String?,
                                            errorMessage: String?) {
        self.trackedAppleTransactionQueueReceivedParams.modify {
            $0.append((productId, paymentDiscountId, transactionState, storefront, errorMessage))
        }
    }

    let trackedAppleTransactionUpdateReceivedParams: Atomic<[
        // swiftlint:disable:next large_tuple
        (transactionId: UInt64,
         environment: String?,
         storefront: String?,
         productId: String,
         purchaseDate: Date,
         expirationDate: Date?,
         price: Float?,
         currency: String?,
         reason: String?)
    ]> = .init([])

    // swiftlint:disable:next function_parameter_count
    func trackAppleTransactionUpdateReceived(transactionId: UInt64,
                                             environment: String?,
                                             storefront: String?,
                                             productId: String,
                                             purchaseDate: Date,
                                             expirationDate: Date?,
                                             price: Float?,
                                             currency: String?,
                                             reason: String?) {
        self.trackedAppleTransactionUpdateReceivedParams.modify {
            $0.append((transactionId: transactionId,
                       environment: environment,
                       storefront: storefront,
                       productId: productId,
                       purchaseDate: purchaseDate,
                       expirationDate: expirationDate,
                       price: price,
                       currency: currency,
                       reason: reason))
        }
    }

    let trackedAppleAppTransactionErrorReceivedParams: Atomic<[
        (errorMessage: String,
        errorCode: Int?,
        storeKitErrorDescription: String?)
    ]> = .init([])

    func trackAppleAppTransactionError(errorMessage: String,
                                       errorCode: Int?,
                                       storeKitErrorDescription: String?) {
        self.trackedAppleAppTransactionErrorReceivedParams.modify {
            $0.append((
                errorMessage: errorMessage,
                errorCode: errorCode,
                storeKitErrorDescription: storeKitErrorDescription
            ))
        }
    }

}
