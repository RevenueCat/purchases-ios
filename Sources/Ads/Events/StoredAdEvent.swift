//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoredAdEvent.swift
//
//  Created by RevenueCat on 1/21/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

/// Contains the necessary information for storing and sending ad events.
struct StoredAdEvent {

    private(set) var encodedEvent: String
    private(set) var userID: String
    private(set) var appSessionID: UUID

    init?<T: Encodable>(event: T, userID: String, appSessionID: UUID) {
        guard let data = try? JSONEncoder.sortedKeys.encode(event),
              let encodedJSON = String(data: data, encoding: .utf8) else {
            return nil
        }

        self.encodedEvent = encodedJSON
        self.userID = userID
        self.appSessionID = appSessionID
    }

}

// MARK: - Extensions

extension StoredAdEvent: Sendable {}

extension StoredAdEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case encodedEvent = "event"
        case userID = "userId"
        case appSessionID = "appSessionId"

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.encodedEvent = try container.decode(String.self, forKey: .encodedEvent)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.appSessionID = try container.decode(UUID.self, forKey: .appSessionID)
    }

}

extension StoredAdEvent: Equatable {}

#endif
