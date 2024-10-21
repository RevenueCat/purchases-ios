//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Untitled.swift
//
//  Created by Cesar de la Vega on 21/10/24.

// This is a `struct` instead of `enum` so that
// we can use make it conform to Encodable
// swiftlint:disable:next convenience_type
struct CustomerCenterEventRequest {

    enum EventType: String {

        case impression = "customer_center_impression"

    }

    struct Event: FeatureEvent {

        let id: String?
        let version: Int
        var type: EventType
        var appUserID: String
        var sessionID: String

    }

}

extension CustomerCenterEventRequest.Event {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: PaywallStoredEvent) {
        guard let eventData = storedEvent.event.value as? [String: Any],
              let paywallEvent: CustomerCenterEvent = try? JSONDecoder.default.decode(dictionary: eventData) else {
            return nil
        }
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
private extension CustomerCenterEvent {

    var eventType: CustomerCenterEventRequest.EventType {
        switch self {
        case .impression: return .impression
        }

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
