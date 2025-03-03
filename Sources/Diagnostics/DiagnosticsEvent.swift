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

struct DiagnosticsEvent: Codable {

    let version: Int = 1
    let eventType: EventType
    let properties: Properties
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case version, properties, timestamp, eventType
    }

    enum EventType: String, Codable {
        case httpRequestPerformed = "http_request_performed"
        case appleProductsRequest = "apple_products_request"
        case customerInfoVerificationResult = "customer_info_verification_result"
        case maxEventsStoredLimitReached = "max_events_stored_limit_reached"
        case applePurchaseAttempt = "apple_purchase_attempt"
    }

    enum PurchaseResult: String, Codable {
        case verified = "verified"
        case unverified = "unverified"
        case userCancelled = "user_cancelled"
        case pending = "pending"
    }

    struct Properties: Codable {
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

        enum CodingKeys: String, CodingKey {
            case verificationResult = "verification_result"
            case endpointName = "endpoint_name"
            case responseTimeMillis = "response_time_millis"
            case storeKitVersion = "store_kit_version"
            case successful
            case responseCode = "response_code"
            case backendErrorCode = "backend_error_code"
            case errorMessage = "error_message"
            case errorCode = "error_code"
            case skErrorDescription = "sk_error_description"
            case eTagHit = "etag_hit"
            case requestedProductIds = "requested_product_ids"
            case notFoundProductIds = "not_found_product_ids"
            case productId = "product_id"
            case promotionalOfferId = "promotional_offer_id"
            case winBackOfferApplied = "win_back_offer_applied"
            case purchaseResult = "purchase_result"
        }

        init(verificationResult: String? = nil,
             endpointName: String? = nil,
             responseTimeMillis: Int? = nil,
             storeKitVersion: String? = nil,
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
             purchaseResult: PurchaseResult? = nil) {
            self.verificationResult = verificationResult
            self.endpointName = endpointName
            self.responseTimeMillis = responseTimeMillis
            self.storeKitVersion = storeKitVersion
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
        }

        static let empty = Properties()
    }
}
