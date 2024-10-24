//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsRequest.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// The content of a request to the events endpoints.
struct EventsRequest {

    var events: [AnyEncodable]

    init(events: [AnyEncodable]) {
        self.events = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [PaywallStoredEvent]) {
        self.init(events: events.compactMap { storedEvent in
            switch storedEvent.feature {
            case .paywalls:
                guard let event = PaywallEventRequest(storedEvent: storedEvent) else {
                    return nil
                }
                return AnyEncodable(event)
            }
        })
    }

}

protocol FeatureEvent: Encodable {

    var id: String? { get }
    var version: Int { get }
    var appUserID: String { get }
    var sessionID: String { get }

}

// This is a `struct` instead of `enum` so that
// we can use make it conform to Encodable
// swiftlint:disable:next convenience_type
struct PaywallEventRequest: FeatureEvent {

    enum EventType: String {

        case impression = "paywall_impression"
        case cancel = "paywall_cancel"
        case close = "paywall_close"

    }

    let id: String?
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

extension PaywallEventRequest {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: PaywallStoredEvent) {
        guard let eventData = storedEvent.event.value as? [String: Any],
              let paywallEvent: PaywallEvent = try? JSONDecoder.default.decode(dictionary: eventData) else {
            return nil
        }

        let creationData = paywallEvent.creationData
        let data = paywallEvent.data

        self.init(
            id: creationData.id.uuidString,
            version: Self.version,
            type: paywallEvent.eventType,
            appUserID: storedEvent.userID,
            sessionID: data.sessionIdentifier.uuidString,
            offeringID: data.offeringIdentifier,
            paywallRevision: data.paywallRevision,
            timestamp: creationData.date.millisecondsSince1970,
            displayMode: data.displayMode,
            darkMode: data.darkMode,
            localeIdentifier: data.localeIdentifier
        )
    }

    private static let version: Int = 1

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEvent {

    var eventType: PaywallEventRequest.EventType {
        switch self {
        case .impression: return .impression
        case .cancel: return .cancel
        case .close: return .close
        }

    }

}

// MARK: - Codable

extension PaywallEventRequest.EventType: Encodable {}
extension PaywallEventRequest: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"
        case offeringID = "offeringId"
        case paywallRevision
        case timestamp
        case displayMode
        case darkMode
        case localeIdentifier = "locale"

    }

}

extension EventsRequest: HTTPRequestBody {}
