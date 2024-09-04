//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsEventsRequest.swift
//
//  Created by Cesar de la Vega on 11/4/24.

import Foundation

/// The content of a request to the events endpoints.
struct DiagnosticsEventsRequest {

    var entries: [Event]

    init(events: [Event]) {
        self.entries = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [DiagnosticsEvent]) {
        self.init(events: events.map { .init(event: $0) })
    }

}

extension DiagnosticsEventsRequest {

    struct Event {

        let version: Int
        let name: String
        let properties: [String: AnyEncodable]
        let timestamp: String

    }

}

extension DiagnosticsEventsRequest.Event {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(event: DiagnosticsEvent) {
        self.init(
            version: event.version,
            name: event.eventType.name,
            properties: event.properties.mapKeys { $0.name },
            timestamp: event.timestamp.ISO8601Format()
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsEvent.EventType {

    var name: String {
        switch self {
        case .httpRequestPerformed: return "http_request_performed"
        case .customerInfoVerificationResult: return "customer_info_verification_result"
        case .maxEventsStoredLimitReached: return "max_events_stored_limit_reached"
        }

    }

}

private extension DiagnosticsEvent.DiagnosticsPropertyKey {

    var name: String {
        switch self {
        case .verificationResultKey:
            return "verification_result"
        case .endpointNameKey:
            return "endpoint_name"
        case .responseTimeMillisKey:
            return "response_time_millis"
        case .successfulKey:
            return "successful"
        case .responseCodeKey:
            return "response_code"
        case .backendErrorCodeKey:
            return "backend_error_code"
        case .eTagHitKey:
            return "etag_hit"
        }
    }

}

// MARK: - Codable

extension DiagnosticsEventsRequest.Event: Encodable {

    enum CodingKeys: String, CodingKey {

        case version, name, properties, timestamp

    }

}

extension DiagnosticsEventsRequest: HTTPRequestBody {}
