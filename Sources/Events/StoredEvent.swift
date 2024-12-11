//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoredEvent.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

/// Contains the necessary information for storing and sending events.
struct StoredEvent {

    private(set) var encodedEvent: String
    private(set) var userID: String
    private(set) var feature: Feature
    private(set) var appSessionID: UUID?
    private(set) var eventDiscriminator: String?

    init?<T: Encodable>(event: T, userID: String, feature: Feature, appSessionID: UUID?, eventDiscriminator: String?) {
        guard let encodedJSON = try? event.encodedJSON else {
            return nil
        }

        self.encodedEvent = encodedJSON
        self.userID = userID
        self.feature = feature
        self.appSessionID = appSessionID
        self.eventDiscriminator = eventDiscriminator
    }

}

enum Feature: String, Codable {

    case paywalls
    case customerCenter

}

// MARK: - Extensions

extension StoredEvent: Sendable {}

extension StoredEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case encodedEvent = "event"
        case userID = "userId"
        case feature
        case appSessionID = "appSessionId"
        case eventDiscriminator = "eventDiscriminator"

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode as string first (new format)
        if let jsonString = try? container.decode(String.self, forKey: .encodedEvent) {
            self.encodedEvent = jsonString
        } else {
            // Fall back to old format (direct dictionary)
            if let oldEvent = try? container.decode(AnyEncodable.self, forKey: .encodedEvent),
               let jsonString = try? oldEvent.encodedJSON {
                self.encodedEvent = jsonString
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [CodingKeys.encodedEvent],
                        debugDescription: "Could not convert old format to JSON string"
                    )
                )
            }
        }

        self.userID = try container.decode(String.self, forKey: .userID)
        if let featureString = try container.decodeIfPresent(String.self, forKey: .feature),
           let feature = Feature(rawValue: featureString) {
            self.feature = feature
        } else {
            self.feature = .paywalls
        }

        if let appSessionID = try container.decodeIfPresent(UUID.self, forKey: .appSessionID) {
            self.appSessionID = appSessionID
        }

        if let eventDiscriminator = try container.decodeIfPresent(String.self, forKey: .eventDiscriminator) {
            self.eventDiscriminator = eventDiscriminator
        }
    }

}

extension StoredEvent: Equatable {

    static func == (lhs: StoredEvent, rhs: StoredEvent) -> Bool {
        guard lhs.userID == rhs.userID,
              lhs.feature == rhs.feature,
              lhs.appSessionID == rhs.appSessionID,
              lhs.eventDiscriminator == rhs.eventDiscriminator else {
            return false
        }

        // Compare decoded events instead of raw JSON strings
        guard let lhsData = lhs.encodedEvent.data(using: .utf8),
              let rhsData = rhs.encodedEvent.data(using: .utf8),
              let lhsDict = try? JSONSerialization.jsonObject(with: lhsData) as? [String: Any],
              let rhsDict = try? JSONSerialization.jsonObject(with: rhsData) as? [String: Any] else {
            return false
        }

        return NSDictionary(dictionary: lhsDict).isEqual(rhsDict)
    }

}
