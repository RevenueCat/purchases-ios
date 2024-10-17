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
struct FeatureEventsRequest: HTTPRequestBody {

    var events: [AnyEncodable]

    init(events: [AnyEncodable]) {
        self.events = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [any AnyStoredFeatureEventType]) {
        self.init(events: events.map { storedEvent in
            switch storedEvent.anyEvent {
            case is PaywallEvent:
                return AnyEncodable(PaywallEventsRequest.Event(storedEvent: storedEvent as! StoredFeatureEvent<PaywallEvent>))
            case is CustomerCenterEvent:
                return AnyEncodable(CustomerCenterEventsRequest.Event(storedEvent: storedEvent as! StoredFeatureEvent<CustomerCenterEvent>))
            default:
                fatalError("Unsupported event type: \(type(of: storedEvent.anyEvent))")
            }
        })
    }

}

struct PaywallEventsRequest {

    enum EventType: String {

        case impression = "paywall_impression"
        case cancel = "paywall_cancel"
        case close = "paywall_close"

    }

    struct Event {

        var id: String?
        var version: Int
        var type: String
        var appUserID: String
        var sessionID: String
        var offeringID: String
        var paywallRevision: Int
        var timestamp: UInt64
        var displayMode: PaywallViewMode
        var darkMode: Bool
        var localeIdentifier: String


        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        init(storedEvent: StoredFeatureEvent<PaywallEvent>) {
            let creationData = storedEvent.event.creationData
            let data = storedEvent.event.data

            self.id = creationData.id.uuidString
            self.version = Self.version
            self.type = storedEvent.event.eventType.rawValue
            self.appUserID = storedEvent.userID
            self.sessionID = data.sessionIdentifier.uuidString
            self.offeringID = data.offeringIdentifier
            self.paywallRevision = data.paywallRevision
            self.timestamp = creationData.date.millisecondsSince1970
            self.displayMode = data.displayMode
            self.darkMode = data.darkMode
            self.localeIdentifier = data.localeIdentifier
        }

        private static let version: Int = 1

    }

}

struct CustomerCenterEventsRequest {

    enum EventType: String {

        case impression = "customer_center_impression"

    }

    struct Event {

        var id: String?
        var version: Int
        var type: String
        var appUserID: String
        var sessionID: String
        var timestamp: UInt64
        var localeIdentifier: String


        @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        init(storedEvent: StoredFeatureEvent<CustomerCenterEvent>) {
            let creationData = storedEvent.event.creationData
            let data = storedEvent.event.data

            self.id = creationData.id.uuidString
            self.version = Self.version
            self.type = storedEvent.event.eventType.rawValue
            self.appUserID = storedEvent.userID
            self.sessionID = data.sessionIdentifier.uuidString
            self.timestamp = creationData.date.millisecondsSince1970
            self.localeIdentifier = data.localeIdentifier
        }

        private static let version: Int = 1

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEvent {

    var eventType: PaywallEventsRequest.EventType {
        switch self {
        case .impression: return .impression
        case .cancel: return .cancel
        case .close: return .close
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterEvent {

    var eventType: CustomerCenterEventsRequest.EventType {
        return .impression
    }

}

// MARK: - Codable

extension PaywallEventsRequest.EventType: Encodable {}

extension CustomerCenterEventsRequest.EventType: Encodable {}
extension PaywallEventsRequest.Event: Encodable {

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

extension CustomerCenterEventsRequest.Event: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"
        case timestamp
        case localeIdentifier = "locale"

    }

}

