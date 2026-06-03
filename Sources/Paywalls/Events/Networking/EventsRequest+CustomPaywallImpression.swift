//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsRequest+CustomPaywallImpression.swift
//
//  Created by Rick van der Linden.

import Foundation

/// Type alias to resolve naming ambiguity inside `FeatureEventsRequest.CustomPaywallEvent`.
private typealias StoredCustomPaywallEvent = CustomPaywallEvent

extension FeatureEventsRequest {

    struct CustomPaywallEvent {

        let id: String
        let version: Int
        let type: String
        var appUserID: String
        var appSessionID: String?
        var timestamp: UInt64
        var paywallId: String?
        var offeringId: String?
        var presentedOfferingContext: PresentedOfferingContextData?

    }

}

extension FeatureEventsRequest.CustomPaywallEvent {

    struct PresentedOfferingContextData: Encodable {

        var placementIdentifier: String?
        var targetingRevision: Int?
        var targetingRuleId: String?

        /// Returns `nil` if all fields are `nil`.
        init?(
            placementIdentifier: String?,
            targetingRevision: Int?,
            targetingRuleId: String?
        ) {
            guard placementIdentifier != nil ||
                    targetingRevision != nil ||
                    targetingRuleId != nil else {
                return nil
            }
            self.placementIdentifier = placementIdentifier
            self.targetingRevision = targetingRevision
            self.targetingRuleId = targetingRuleId
        }

    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init?(storedEvent: StoredFeatureEvent) {
        guard let jsonData = storedEvent.encodedEvent.data(using: .utf8) else {
            Logger.error(Strings.paywalls.event_cannot_get_encoded_event)
            return nil
        }

        do {
            let event = try JSONDecoder.default.decode(StoredCustomPaywallEvent.self, from: jsonData)

            self.init(
                id: event.creationData.id.uuidString,
                version: Self.version,
                type: Self.typeName,
                appUserID: storedEvent.userID,
                appSessionID: storedEvent.appSessionID?.uuidString,
                timestamp: event.creationData.date.millisecondsSince1970,
                paywallId: event.data.paywallId,
                offeringId: event.data.offeringId,
                presentedOfferingContext: PresentedOfferingContextData(
                    placementIdentifier: event.data.placementIdentifier,
                    targetingRevision: event.data.targetingRevision,
                    targetingRuleId: event.data.targetingRuleId
                )
            )
        } catch {
            Logger.error(Strings.paywalls.event_cannot_deserialize(error))
            return nil
        }
    }

    private static let version: Int = 1
    private static let typeName: String = "custom_paywall_impression"

}

// MARK: - Codable

extension FeatureEventsRequest.CustomPaywallEvent: Encodable {

    private enum CodingKeys: String, CodingKey {

        case id
        case version
        case type
        case appUserID = "appUserId"
        case appSessionID = "appSessionId"
        case timestamp
        case paywallId
        case offeringId
        case presentedOfferingContext

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)
        try container.encode(type, forKey: .type)
        try container.encode(appUserID, forKey: .appUserID)
        try container.encodeIfPresent(appSessionID, forKey: .appSessionID)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(paywallId, forKey: .paywallId)
        try container.encodeIfPresent(offeringId, forKey: .offeringId)
        try container.encodeIfPresent(presentedOfferingContext, forKey: .presentedOfferingContext)
    }

}
