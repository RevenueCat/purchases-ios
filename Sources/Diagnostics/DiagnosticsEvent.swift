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

    private(set) var version: Int = 1
    let name: EventName
    let properties: Properties
    let timestamp: Date

    enum EventName: String, Codable, Equatable {
        case httpRequestPerformed = "http_request_performed"
        case appleProductsRequest = "apple_products_request"
        case customerInfoVerificationResult = "customer_info_verification_result"
        case maxEventsStoredLimitReached = "max_events_stored_limit_reached"
        case applePurchaseAttempt = "apple_purchase_attempt"
    }

    enum PurchaseResult: String, Codable, Equatable {
        case verified
        case unverified
        case userCancelled = "user_cancelled"
        case pending
    }

    struct Properties: Codable, Equatable {
        let verificationResult: String?
        let endpointName: String?
        let responseTimeMillis: Int?
        let storeKitVersion: String?
        let successful: Bool?
        let responseCode: Int?
        let backendErrorCode: Int?
        let errorMessage: String?
        let errorCode: Int?
        let skErrorDescription: String?
        let eTagHit: Bool?
        let requestedProductIds: Set<String>?
        let notFoundProductIds: Set<String>?
        let productId: String?
        let promotionalOfferId: String?
        let winBackOfferApplied: Bool?
        let purchaseResult: PurchaseResult?
        let isRetry: Bool?

        init(verificationResult: String? = nil,
             endpointName: String? = nil,
             responseTime: TimeInterval? = nil,
             storeKitVersion: StoreKitVersion? = nil,
             successful: Bool? = nil,
             responseCode: Int? = nil,
             backendErrorCode: Int? = nil,
             errorMessage: String? = nil,
             errorCode: Int? = nil,
             skErrorDescription: String? = nil,
             eTagHit: Bool? = nil,
             requestedProductIds: Set<String>? = nil,
             notFoundProductIds: Set<String>? = nil,
             productId: String? = nil,
             promotionalOfferId: String? = nil,
             winBackOfferApplied: Bool? = nil,
             purchaseResult: PurchaseResult? = nil,
             isRetry: Bool? = nil) {
            self.verificationResult = verificationResult
            self.endpointName = endpointName
            self.responseTimeMillis = responseTime.map { Int($0 * 1000) }
            self.storeKitVersion = storeKitVersion.map { "store_kit_\($0.debugDescription)" }
            self.successful = successful
            self.responseCode = responseCode
            self.backendErrorCode = backendErrorCode
            self.errorMessage = errorMessage
            self.errorCode = errorCode
            self.skErrorDescription = skErrorDescription
            self.eTagHit = eTagHit
            self.requestedProductIds = requestedProductIds
            self.notFoundProductIds = notFoundProductIds
            self.productId = productId
            self.promotionalOfferId = promotionalOfferId
            self.winBackOfferApplied = winBackOfferApplied
            self.purchaseResult = purchaseResult
            self.isRetry = isRetry
        }

        static let empty = Properties()
    }
}
