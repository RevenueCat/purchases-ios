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

    private(set) var encodedEvent: AnyEncodable
    private(set) var userID: String
    private(set) var feature: Feature

    init?<T: Encodable>(event: T, userID: String, feature: Feature) {
        guard let data = try? event.encodedJSON else {
            return nil
        }

        self.encodedEvent = AnyEncodable(data)
        self.userID = userID
        self.feature = feature
    }

}

enum Feature: String, Codable {

    case paywalls

}

// MARK: - Extensions

extension StoredEvent: Sendable {}

extension StoredEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case encodedEvent = "event"
        case userID = "userId"
        case feature

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode as string first (new format)
        if let jsonString = try? container.decode(String.self, forKey: .encodedEvent) {
            if let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) {
                self.encodedEvent = AnyEncodable(jsonObject)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [CodingKeys.encodedEvent],
                        debugDescription: "Could not parse stored JSON string"
                    )
                )
            }
        } else {
            // Fall back to old format (direct dictionary)
            self.encodedEvent = try container.decode(AnyEncodable.self, forKey: .encodedEvent)
        }

        self.userID = try container.decode(String.self, forKey: .userID)
        if let featureString = try container.decodeIfPresent(String.self, forKey: .feature),
           let feature = Feature(rawValue: featureString) {
            self.feature = feature
        } else {
            self.feature = .paywalls
        }
    }

}

extension StoredEvent: Equatable {

    static func == (lhs: StoredEvent, rhs: StoredEvent) -> Bool {
        guard let lhsValue = lhs.encodedEvent.value as? [String: Any],
              let rhsValue = rhs.encodedEvent.value as? [String: Any] else {
            return false
        }

        return lhs.userID == rhs.userID &&
               lhs.feature == rhs.feature &&
               (lhsValue as NSDictionary).isEqual(to: rhsValue)
    }

}
