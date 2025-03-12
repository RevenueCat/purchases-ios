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

<<<<<<< HEAD
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

=======
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
>>>>>>> f719448ec1170883da138f91816eb9bc95ea1af9
}
