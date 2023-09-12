//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsRequest.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// The content of a request to the events endpoints.
struct PaywallEventsRequest {

    var events: [Event]

    init(events: [Event]) {
        self.events = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [PaywallStoredEvent]) {
        self.init(events: events.map { .init(storedEvent: $0) })
    }

}

extension PaywallEventsRequest {

    enum EventType: String {

        case view
        case cancel
        case close

    }

    struct Event {

        let version: Int
        var type: EventType
        var appUserID: String
        var sessionID: String
        var offeringID: String
        var paywallRevision: Int
        var timestamp: UInt64
        var displayMode: PaywallViewMode
        var darkMode: Bool
        var localeIdentifier: String

    }

}

extension PaywallEventsRequest.Event {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(storedEvent: PaywallStoredEvent) {
        let data = storedEvent.event.data

        self.init(
            version: Self.version,
            type: storedEvent.event.eventType,
            appUserID: storedEvent.userID,
            sessionID: data.sessionIdentifier.uuidString,
            offeringID: data.offeringIdentifier,
            paywallRevision: data.paywallRevision,
            timestamp: data.date.millisecondsSince1970,
            displayMode: data.displayMode,
            darkMode: data.darkMode,
            localeIdentifier: data.localeIdentifier
        )
    }

    private static let version: Int = 1

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEvent {

    var eventType: PaywallEventsRequest.EventType {
        switch self {
        case .view: return .view
        case .cancel: return .cancel
        case .close: return .close
        }

    }

}

// MARK: - Codable

extension PaywallEventsRequest.EventType: Encodable {}

extension PaywallEventsRequest.Event: Encodable {

    private enum CodingKeys: String, CodingKey {

        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"
        case offeringID = "offeringId"
        case paywallRevision
        case timestamp
        case displayMode
        case darkMode
        case localeIdentifier

    }

}

extension PaywallEventsRequest: HTTPRequestBody {}
