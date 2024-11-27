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

    struct CustomerCenterEvent {

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
        case close = "customer_center_close"
        case surveyCompleted = "customer_center_survey_completed"

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredEvent) {
        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let customerCenterEvent = try JSONDecoder.default.decode(CustomerCenterEvent.self, from: jsonData)
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
        case .close: return .close
        case .surveyCompleted: return .surveyCompleted
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
