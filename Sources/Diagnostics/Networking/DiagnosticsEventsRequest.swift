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
            properties: event.properties,
            timestamp: event.timestamp.ISO8601Format()
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsEvent.EventType {

    var name: String {
        switch self {
        case .httpRequestPerformed: return "HTTP_REQUEST_PERFORMED"
        case .customerInfoVerificationResult: return "CUSTOMER_INFO_VERIFICATION_RESULT"
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
