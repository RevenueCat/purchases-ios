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

import Foundation

extension EventsRequest {

    struct CustomerCenterEvent: FeatureEvent {

        let id: String?
        let version: Int
        var type: EventType
        var appUserID: String
        var sessionID: String
        var timestamp: UInt64
        var darkMode: Bool
        var localeIdentifier: String

    }

}

extension EventsRequest.CustomerCenterEvent {

    enum EventType: String {

        case impression = "customer_center_impression"

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredEvent) {
        guard let eventData = storedEvent.encodedEvent.value as? [String: Any] else {
            return nil
        }
        do {
            let customerCenterEvent: CustomerCenterEvent = try JSONDecoder.default.decode(dictionary: eventData)
            let creationData = customerCenterEvent.creationData
            let data = customerCenterEvent.data

            self.init(
                id: creationData.id.uuidString,
                version: Self.version,
                type: customerCenterEvent.eventType,
                appUserID: storedEvent.userID,
                sessionID: data.sessionIdentifier.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                darkMode: data.darkMode,
                localeIdentifier: data.localeIdentifier
            )
        } catch {
            return nil
        }
    }

    private static let version: Int = 1

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterEvent {

    var eventType: EventsRequest.CustomerCenterEvent.EventType {
        switch self {
        case .impression: return .impression
        }

    }

}

// MARK: - Codable

extension EventsRequest.CustomerCenterEvent.EventType: Encodable {}
extension EventsRequest.CustomerCenterEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case sessionID = "sessionId"
        case timestamp
        case darkMode
        case localeIdentifier = "locale"

    }

}
