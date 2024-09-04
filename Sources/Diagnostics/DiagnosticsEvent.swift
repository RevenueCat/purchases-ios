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

struct DiagnosticsEvent: Codable, Equatable {

    let version: Int = 1
    let eventType: DiagnosticsEvent.EventType
    let properties: [DiagnosticsPropertyKey: AnyEncodable]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case version, properties, timestamp, eventType
    }

}

extension DiagnosticsEvent {

    enum EventType: String, Codable {

        case httpRequestPerformed
        case customerInfoVerificationResult
        case maxEventsStoredLimitReached

    }

    enum DiagnosticsPropertyKey: String, Codable {

        case verificationResultKey
        case endpointNameKey
        case responseTimeMillisKey
        case successfulKey
        case responseCodeKey
        case backendErrorCodeKey
        case eTagHitKey

    }

}

extension DiagnosticsEvent {

    static func == (lhs: DiagnosticsEvent, rhs: DiagnosticsEvent) -> Bool {
        return lhs.version == rhs.version &&
               lhs.eventType == rhs.eventType &&
               lhs.properties == rhs.properties &&
               lhs.timestamp == rhs.timestamp
    }

}
