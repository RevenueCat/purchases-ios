//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponent.swift
//
//  Created by James Borthwick on 2024-08-20.
// swiftlint:disable missing_docs nesting
import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct StackComponent: PaywallComponentBase {

        let type: ComponentType
        public let components: [PaywallComponent]
        public let spacing: CGFloat?
        public let backgroundColor: ColorInfo?
        public let dimension: Dimension
        public let padding: Padding

        public init(components: [PaywallComponent],
                    dimension: Dimension = .vertical(.center),
                    spacing: CGFloat?,
                    backgroundColor: ColorInfo?,
                    padding: Padding
        ) {
            self.components = components
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.type = .stack
            self.dimension = dimension
            self.padding = padding
        }

        public enum Dimension: Codable, Sendable, Hashable {

            case vertical(HorizontalAlignment)
            case horizontal(VerticalAlignment)
            case zlayer(TwoDimensionAlignment)

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .vertical(let alignment):
                    try container.encode(DimensionType.vertical.rawValue, forKey: .type)
                    try container.encode(alignment, forKey: .alignment)
                case .horizontal(let alignment):
                    try container.encode(DimensionType.horizontal.rawValue, forKey: .type)
                    try container.encode(alignment, forKey: .alignment)
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
                    self = .vertical(alignment)
                case .horizontal:
                    let alignment = try container.decode(VerticalAlignment.self, forKey: .alignment)
                    self = .horizontal(alignment)
                case .zlayer:
                    let alignment = try container.decode(TwoDimensionAlignment.self, forKey: .alignment)
                    self = .zlayer(alignment)
                }
            }

            public static func horizontal() -> Dimension {
                return .horizontal(.center)
            }

            public static func vertical() -> Dimension {
                return .vertical(.center)
            }

            private enum CodingKeys: String, CodingKey {

                case type
                case alignment

            }

            private enum DimensionType: String, Decodable {

                case vertical
                case horizontal
                case zlayer

            }

        }

    }
}

#endif
