//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEventsRequest+CheckpointEvent.swift

import Foundation

/// Type alias to avoid naming conflict inside `FeatureEventsRequest.CheckpointEvent`.
private typealias StoredCheckpointEvent = CheckpointEvent

extension FeatureEventsRequest {

    /// Khepri-compatible wire format for checkpoint hits.
    struct CheckpointEvent {

        let id: String
        let version: Int
        let type: String
        let identifier: String
        let appUserID: String
        let sessionID: String?
        let timestamp: UInt64

    }

}

extension FeatureEventsRequest.CheckpointEvent {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredFeatureEvent) {
        guard storedEvent.feature == .checkpoints else { return nil }

        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let event = try JSONDecoder.default.decode(StoredCheckpointEvent.self, from: jsonData)

            self.init(
                id: event.id.uuidString,
                version: Self.schemaVersion,
                type: Self.typeValue,
                identifier: event.identifier,
                appUserID: storedEvent.userID,
                sessionID: storedEvent.appSessionID?.uuidString,
                timestamp: event.date.millisecondsSince1970
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let schemaVersion = 1
    private static let typeValue = "checkpoint_hit"

}

// MARK: - Encodable

extension FeatureEventsRequest.CheckpointEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case identifier
        case appUserID = "app_user_id"
        case sessionID = "session_id"
        case timestamp

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encodeIfPresent(self.sessionID, forKey: .sessionID)
        try container.encode(self.timestamp, forKey: .timestamp)
    }

}
