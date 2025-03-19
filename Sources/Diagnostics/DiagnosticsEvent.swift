//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsEntry.swift
//
//  Created by Cesar de la Vega on 1/4/24.

import Foundation

/// When sending this to the backend `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase` is used.
struct DiagnosticsEvent: Codable, Equatable {

    let id: UUID
    private(set) var version: Int = 1
    let name: EventName
    let properties: Properties
    let timestamp: Date
    let appSessionId: UUID

    init(id: UUID = UUID(),
         name: EventName,
         properties: Properties,
         timestamp: Date,
         appSessionId: UUID) {
        self.id = id
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
        self.appSessionId = appSessionId
    }

    enum EventName: String, Codable, Equatable {
        case httpRequestPerformed = "http_request_performed"
        case appleProductsRequest = "apple_products_request"
        case customerInfoVerificationResult = "customer_info_verification_result"
        case maxEventsStoredLimitReached = "max_events_stored_limit_reached"
        case clearingDiagnosticsAfterFailedSync = "clearing_diagnostics_after_failed_sync"
        case enteredOfflineEntitlementsMode = "entered_offline_entitlements_mode"
        case errorEnteringOfflineEntitlementsMode = "error_entering_offline_entitlements_mode"
        case applePurchaseAttempt = "apple_purchase_attempt"
        case maxDiagnosticsSyncRetriesReached = "max_diagnostics_sync_retries_reached"
        case getOfferingsStarted = "get_offerings_started"
        case getOfferingsResult = "get_offerings_result"
        case getProductsStarted = "get_products_started"
        case getProductsResult = "get_products_result"
        case getCustomerInfoStarted = "get_customer_info_started"
        case getCustomerInfoResult = "get_customer_info_result"
        case syncPurchasesStarted = "sync_purchases_started"
        case syncPurchasesResult = "sync_purchases_result"
        case restorePurchasesStarted = "restore_purchases_started"
        case restorePurchasesResult = "restore_purchases_result"
        case applePresentCodeRedemptionSheetRequest = "apple_present_code_redemption_sheet_request"
        case appleTrialOrIntroEligibilityRequest = "apple_trial_or_intro_eligibility_request"
        case appleTransactionQueueReceived = "apple_transaction_queue_received"
    }

    enum PurchaseResult: String, Codable, Equatable {
        case verified = "VERIFIED"
        case unverified = "UNVERIFIED"
        case userCancelled = "USER_CANCELLED"
        case pending = "PENDING"
    }

    enum OfflineEntitlementsModeErrorReason: String, Codable, Equatable {
        case oneTimePurchaseFound = "ONE_TIME_PURCHASE_FOUND"
        case noEntitlementMappingAvailable = "NO_ENTITLEMENT_MAPPING_AVAILABLE"
        case unknown = "UNKNOWN"
    }

    struct Properties: Codable, Equatable {
        let verificationResult: String?
        let endpointName: String?
        let responseTimeMillis: Int?
        let storeKitVersion: String?
        let successful: Bool?
        let responseCode: Int?
        let backendErrorCode: Int?
        let offlineEntitlementErrorReason: OfflineEntitlementsModeErrorReason?
        let errorMessage: String?
        let errorCode: Int?
        let skErrorDescription: String?
        let etagHit: Bool?
        let requestedProductIds: Set<String>?
        let notFoundProductIds: Set<String>?
        let productId: String?
        let promotionalOfferId: String?
        let winBackOfferApplied: Bool?
        let purchaseResult: PurchaseResult?
        let cacheStatus: CacheStatus?
        let cacheFetchPolicy: String?
        let hadUnsyncedPurchasesBefore: Bool?
        let isRetry: Bool?
        let eligibilityUnknownCount: Int?
        let eligibilityIneligibleCount: Int?
        let eligibilityEligibleCount: Int?
        let eligibilityNoIntroOfferCount: Int?

        init(verificationResult: String? = nil,
             endpointName: String? = nil,
             responseTime: TimeInterval? = nil,
             storeKitVersion: StoreKitVersion? = nil,
             successful: Bool? = nil,
             responseCode: Int? = nil,
             backendErrorCode: Int? = nil,
             offlineEntitlementErrorReason: OfflineEntitlementsModeErrorReason? = nil,
             errorMessage: String? = nil,
             errorCode: Int? = nil,
             skErrorDescription: String? = nil,
             etagHit: Bool? = nil,
             requestedProductIds: Set<String>? = nil,
             notFoundProductIds: Set<String>? = nil,
             productId: String? = nil,
             promotionalOfferId: String? = nil,
             winBackOfferApplied: Bool? = nil,
             purchaseResult: PurchaseResult? = nil,
             cacheStatus: CacheStatus? = nil,
             cacheFetchPolicy: CacheFetchPolicy? = nil,
             hadUnsyncedPurchasesBefore: Bool? = nil,
             isRetry: Bool? = nil,
             eligibilityUnknownCount: Int? = nil,
             eligibilityIneligibleCount: Int? = nil,
             eligibilityEligibleCount: Int? = nil,
             eligibilityNoIntroOfferCount: Int? = nil
        ) {
            self.verificationResult = verificationResult
            self.endpointName = endpointName
            self.responseTimeMillis = responseTime.map { Int($0 * 1000) }
            self.storeKitVersion = storeKitVersion.map { "store_kit_\($0.debugDescription)" }
            self.successful = successful
            self.responseCode = responseCode
            self.backendErrorCode = backendErrorCode
            self.offlineEntitlementErrorReason = offlineEntitlementErrorReason
            self.errorMessage = errorMessage
            self.errorCode = errorCode
            self.skErrorDescription = skErrorDescription
            self.etagHit = etagHit
            self.requestedProductIds = requestedProductIds
            self.notFoundProductIds = notFoundProductIds
            self.productId = productId
            self.promotionalOfferId = promotionalOfferId
            self.winBackOfferApplied = winBackOfferApplied
            self.purchaseResult = purchaseResult
            self.cacheStatus = cacheStatus
            self.cacheFetchPolicy = cacheFetchPolicy.map { $0.diagnosticsName }
            self.hadUnsyncedPurchasesBefore = hadUnsyncedPurchasesBefore
            self.isRetry = isRetry
            self.eligibilityUnknownCount = eligibilityUnknownCount
            self.eligibilityIneligibleCount = eligibilityIneligibleCount
            self.eligibilityEligibleCount = eligibilityEligibleCount
            self.eligibilityNoIntroOfferCount = eligibilityNoIntroOfferCount
        }

        static let empty = Properties()
    }
}

fileprivate extension CacheFetchPolicy {

    var diagnosticsName: String {
        switch self {
        case .fromCacheOnly: return "FROM_CACHE_ONLY"
        case .fetchCurrent: return "FETCH_CURRENT"
        case .notStaleCachedOrFetched: return "NOT_STALE_CACHED_OR_FETCHED"
        case .cachedOrFetched: return "CACHED_OR_FETCHED"
        }
    }
}
