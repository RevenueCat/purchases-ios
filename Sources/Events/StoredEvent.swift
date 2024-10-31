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

    var event: AnyEncodable
    var userID: String
    var feature: Feature

}

enum Feature: String, Codable {

    case paywalls

}

// MARK: - Extensions

extension StoredEvent: Equatable, Sendable {}

extension StoredEvent: Codable {

    private enum CodingKeys: String, CodingKey {

        case event
        case userID = "userId"
        case feature

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.event = try container.decode(AnyEncodable.self, forKey: .event)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.feature = try container.decodeIfPresent(Feature.self, forKey: .feature) ?? .paywalls
    }

}
