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
struct DiagnosticsEvent: Codable {

    let version: Int = 1
    let eventType: EventType
    let properties: Properties
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case version, properties, timestamp, eventType
    }

    enum EventType: Codable {
        case httpRequestPerformed
        case appleProductsRequest
        case customerInfoVerificationResult
        case maxEventsStoredLimitReached
        case applePurchaseAttempt
    }

    enum PurchaseResult: Codable {
        case verified
        case unverified
        case userCancelled
        case pending
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
