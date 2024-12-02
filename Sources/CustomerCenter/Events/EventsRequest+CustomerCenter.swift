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
        var appSessionID: String
        var timestamp: UInt64
        var darkMode: Bool
        var locale: String
        var isSandbox: Bool
        var displayMode: CustomerCenterPresentationMode

    }

}

extension EventsRequest.CustomerCenterEvent {

    enum EventType: String {

        case impression = "customer_center_impression"
        case close = "customer_center_close"

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredEvent) {
        guard let appSessionID = storedEvent.appSessionID else {
            Logger.error(Strings.paywalls.event_missing_app_session_id)
            return nil
        }

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
                appSessionID: appSessionID.uuidString,
                timestamp: creationData.date.millisecondsSince1970,
                darkMode: data.darkMode,
                locale: data.localeIdentifier,
                isSandbox: data.isSandbox,
                displayMode: data.displayMode
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
        case appSessionID = "appSessionId"
        case timestamp
        case darkMode = "darkMode"
        case locale
        case isSandbox = "isSandbox"
        case displayMode = "displayMode"

    }

}
