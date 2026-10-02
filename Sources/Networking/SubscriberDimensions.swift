//
//  SubscriberDimensions.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// The backend's view of a subscriber's dimensions at a specific server instant.
struct SubscriberDimensions: Equatable, Sendable {

    let values: [String: DimensionValue]
    let asOf: Date

}

extension SubscriberDimensions: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawDimensions = try container.decode([String: AnyDecodable].self, forKey: .dimensions)
        let milliseconds = try container.decode(UInt64.self, forKey: .asOf)

        self.init(
            values: rawDimensions.compactMapValues(\.dimensionValue),
            asOf: Date(millisecondsSince1970: milliseconds)
        )
    }

    private enum CodingKeys: String, CodingKey {

        case dimensions
        case asOf

    }

}
