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
        let appSessionID: String
        let timestamp: UInt64
        let result: CheckpointHitResult?
        let workflowID: String?
        let offeringID: String?
        let checkpointRuleID: String?

    }

}

extension FeatureEventsRequest.CheckpointEvent {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredFeatureEvent) {
        guard storedEvent.feature == .checkpoints else { return nil }

        guard let appSessionID = storedEvent.appSessionID else {
            Logger.error(Strings.paywalls.event_missing_app_session_id)
            return nil
        }

        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let event = try JSONDecoder.default.decode(StoredCheckpointEvent.self, from: jsonData)

            self.init(
                id: event.data.id.uuidString,
                version: Self.schemaVersion,
                type: event.eventType,
                identifier: event.data.identifier,
                appUserID: storedEvent.userID,
                appSessionID: appSessionID.uuidString,
                timestamp: event.data.date.millisecondsSince1970,
                result: event.data.result,
                workflowID: event.data.workflowID,
                offeringID: event.data.offeringID,
                checkpointRuleID: event.data.checkpointRuleID
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let schemaVersion = 1

}

// MARK: - Encodable

extension FeatureEventsRequest.CheckpointEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case identifier
        case appUserID = "app_user_id"
        case appSessionID = "app_session_id"
        case timestamp
        case result
        case workflowID = "workflow_id"
        case offeringID = "offering_id"
        case checkpointRuleID = "checkpoint_rule_id"

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.appSessionID, forKey: .appSessionID)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.result, forKey: .result)
        try container.encodeIfPresent(self.workflowID, forKey: .workflowID)
        try container.encodeIfPresent(self.offeringID, forKey: .offeringID)
        try container.encodeIfPresent(self.checkpointRuleID, forKey: .checkpointRuleID)
    }

}
