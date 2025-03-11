//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentOverrides.swift
//
//  Created by Josh Holtz on 10/26/24.
//
// swiftlint:disable missing_docs

import Foundation

public protocol PaywallPartialComponent: PaywallComponentBase {}

public extension PaywallComponent {

    typealias ComponentOverrides<T: PaywallPartialComponent> = [ComponentOverride<T>]

    struct ComponentOverride<T: PaywallPartialComponent>: Codable, Sendable, Hashable, Equatable {

        public let conditions: [Condition]
        public let properties: T

        public init(conditions: [Condition], properties: T) {
            self.conditions = conditions
            self.properties = properties
        }

    }

    enum Condition: String, Codable, Sendable, Hashable, Equatable {

        case compact
        case medium
        case expanded
        case introOffer = "intro_offer"
        case selected

        // For unknown cases
        case unsupported

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .compact:
                try container.encodeIfPresent(ConditionType.compact.rawValue, forKey: .type)
            case .medium:
                try container.encode(ConditionType.medium.rawValue, forKey: .type)
            case .expanded:
                try container.encode(ConditionType.expanded.rawValue, forKey: .type)
            case .introOffer:
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
            case .selected:
                try container.encode(ConditionType.selected.rawValue, forKey: .type)
            case .unsupported:
                // Encode a default value for unsupported
                try container.encode(Self.unsupported.rawValue, forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .type)

            if let conditionType = ConditionType(rawValue: rawValue) {
                switch conditionType {
                case .compact:
                    self = .compact
                case .medium:
                    self = .medium
                case .expanded:
                    self = .expanded
                case .introOffer:
                    self = .introOffer
                case .selected:
                    self = .selected
                }
            } else {
                self = .unsupported
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type

        }

        // swiftlint:disable:next nesting
        private enum ConditionType: String, Decodable {

            case compact
            case medium
            case expanded
            case introOffer = "intro_offer"
            case selected

        }

    }

}
