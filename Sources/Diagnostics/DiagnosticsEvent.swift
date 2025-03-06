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

    let id: UUID
    let version: Int = 1
    let eventType: DiagnosticsEvent.EventType
    let properties: [DiagnosticsPropertyKey: AnyEncodable]
    let timestamp: Date
    let appSessionId: UUID?

    init(id: UUID = UUID(),
         eventType: DiagnosticsEvent.EventType,
         properties: [DiagnosticsPropertyKey: AnyEncodable],
         timestamp: Date,
         appSessionId: UUID) {
        self.id = id
        self.eventType = eventType
        self.properties = properties
        self.timestamp = timestamp
        self.appSessionId = appSessionId
    }

    enum CodingKeys: String, CodingKey {
        case id, version, properties, timestamp, eventType, appSessionId
    }

}

extension DiagnosticsEvent {

    enum EventType: String, Codable {

        case httpRequestPerformed
        case appleProductsRequest
        case customerInfoVerificationResult
        case maxEventsStoredLimitReached
        case applePurchaseAttempt

    }

    enum DiagnosticsPropertyKey: String, Codable {

        case verificationResultKey
        case endpointNameKey
        case responseTimeMillisKey
        case storeKitVersion
        case successfulKey
        case responseCodeKey
        case backendErrorCodeKey
        case errorMessageKey
        case errorCodeKey
        case skErrorDescriptionKey
        case eTagHitKey
        case requestedProductIdsKey
        case notFoundProductIdsKey
        case productIdKey
        case promotionalOfferIdKey
        case winBackOfferAppliedKey
        case purchaseResultKey

    }

    /// Value for `purchaseResultKey`.
    enum PurchaseResult: String, Codable {
        case verified = "verified"
        case unverified = "unverified"
        case userCancelled = "user_cancelled"
        case pending = "pending"
    }

}
