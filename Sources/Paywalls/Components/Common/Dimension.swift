//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Dimension.swift
//
//  Created by Josh Holtz on 9/27/24.
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    enum Dimension: Codable, Sendable, Hashable {

        case vertical(HorizontalAlignment, FlexDistribution)
        case horizontal(VerticalAlignment, FlexDistribution)
        case zlayer(TwoDimensionAlignment)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .vertical(let alignment, let distribution):
                try container.encode(DimensionType.vertical.rawValue, forKey: .type)
                try container.encode(alignment, forKey: .alignment)
                try container.encode(distribution, forKey: .distribution)
            case .horizontal(let alignment, let distribution):
                try container.encode(DimensionType.horizontal.rawValue, forKey: .type)
                try container.encode(alignment, forKey: .alignment)
                try container.encode(distribution, forKey: .distribution)
            case .zlayer(let alignment):
                try container.encode(DimensionType.zlayer.rawValue, forKey: .type)
                try container.encode(alignment.rawValue, forKey: .alignment)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(DimensionType.self, forKey: .type)

            switch type {
            case .vertical:
                let alignment = try container.decode(HorizontalAlignment.self, forKey: .alignment)
                let distribution = try container.decode(FlexDistribution.self, forKey: .distribution)
                self = .vertical(alignment, distribution)
            case .horizontal:
                let alignment = try container.decode(VerticalAlignment.self, forKey: .alignment)
                let distribution = try container.decode(FlexDistribution.self, forKey: .distribution)
                self = .horizontal(alignment, distribution)
            case .zlayer:
                let alignment = try container.decode(TwoDimensionAlignment.self, forKey: .alignment)
                self = .zlayer(alignment)
            }
        }

        public static func horizontal() -> Dimension {
            return .horizontal(.center, .start)
        }

        public static func vertical() -> Dimension {
            return .vertical(.center, .start)
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case alignment
            case distribution

        }

        // swiftlint:disable:next nesting
        private enum DimensionType: String, Decodable {

            case vertical
            case horizontal
            case zlayer

        }

    }

}
