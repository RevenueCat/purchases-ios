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

    var events: [AnyEncodable]

    init(events: [AnyEncodable]) {
        self.events = events
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(events: [PaywallStoredEvent]) {
        self.init(events: events.map { storedEvent in
            switch(storedEvent.feature) {
            case .paywalls:
                return AnyEncodable(PaywallEventRequest.Event(storedEvent: storedEvent))
            case .customerCenter:
                return AnyEncodable(CustomerCenterEventRequest.Event(storedEvent: storedEvent))
            }
        })
    }

}

protocol EventProtocol: Encodable {

    var id: String? { get }
    var version: Int { get }
    var appUserID: String { get }
    var sessionID: String { get }

}

struct PaywallEventRequest {

    enum EventType: String {

        case impression = "paywall_impression"
        case cancel = "paywall_cancel"
        case close = "paywall_close"

    }

    struct Event: EventProtocol {

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

}

struct CustomerCenterEventRequest {

    enum EventType: String {

        case impression = "customer_center_impression"

    }

    struct Event: EventProtocol {

        let id: String?
        let version: Int
        var type: EventType
        var appUserID: String
        var sessionID: String

    }

}

extension PaywallEventRequest.Event {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(storedEvent: PaywallStoredEvent) {
        let eventData = storedEvent.event.value as! [String: Any]

        let paywallEvent: PaywallEvent = try! JSONDecoder.default.decode(dictionary: eventData)
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

extension CustomerCenterEventRequest.Event {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(storedEvent: PaywallStoredEvent) {
        let eventData = storedEvent.event.value as! [String: Any]

        let paywallEvent: CustomerCenterEvent = try! JSONDecoder.default.decode(dictionary: eventData)
        let creationData = paywallEvent.creationData
        let data = paywallEvent.data

        self.init(
            id: creationData.id.uuidString,
            version: Self.version,
            type: paywallEvent.eventType,
            appUserID: storedEvent.userID,
            sessionID: data.sessionIdentifier.uuidString
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterEvent {

    var eventType: CustomerCenterEventRequest.EventType {
        switch self {
        case .impression: return .impression
        }

    }

}



// MARK: - Codable

extension PaywallEventRequest: Encodable {}
extension PaywallEventRequest.EventType: Encodable {}
extension PaywallEventRequest.Event: Encodable {

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

extension CustomerCenterEventRequest: Encodable {}
extension CustomerCenterEventRequest.EventType: Encodable {}
extension CustomerCenterEventRequest.Event: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"

    }

}


extension PaywallEventsRequest: HTTPRequestBody {}

//extension PaywallEventsRequest {
//
//    struct Event {
//
//        let storedEvent: PaywallStoredEvent
//
//        private static let version: Int = 1
//
//    }
//
//}
//
//extension PaywallEventsRequest.Event: Encodable {
//
//    private enum CodingKeys: String, CodingKey {
//
//        case version
//
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(Self.version, forKey: .version)
//        
//        // Encode the PaywallStoredEvent directly into the root
//        try storedEvent.encode(to: encoder)
//    }
//
//}
//
//extension PaywallEventsRequest: HTTPRequestBody {}
