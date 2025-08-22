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

    enum Condition: Codable, Sendable, Hashable, Equatable {

        case orientation(ArrayOperatorType, [OrientationType])
        case screenSize(ArrayOperatorType, [String])
        case selectedPackage
        case introOffer
        case promoOffer
        case selected



        // For unknown cases
        case unsupported

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .orientation(let op, let orientations):
                try container.encode(ConditionType.orientation.rawValue, forKey: .type)
                try container.encode(op, forKey: .operator)
                try container.encode(orientations, forKey: .orientations)
            case .screenSize(let op, let screenSizes):
                try container.encode(ConditionType.screenSize.rawValue, forKey: .type)
                try container.encode(op, forKey: .operator)
                try container.encode(screenSizes, forKey: .screenSize)
            case .selectedPackage:
                try container.encode(ConditionType.selectedPackage.rawValue, forKey: .type)
            case .introOffer:
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
            case .promoOffer:
                try container.encode(ConditionType.promoOffer.rawValue, forKey: .type)
            case .selected:
                try container.encode(ConditionType.selected.rawValue, forKey: .type)
            case .unsupported:
                // Encode a default value for unsupported
                try container.encode("unknown", forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .type)

            if let conditionType = ConditionType(rawValue: rawValue) {
                switch conditionType {
                case .orientation:
                    let op = try container.decode(ArrayOperatorType.self, forKey: .operator)
                    let orientations = try container.decode([OrientationType].self, forKey: .orientations)
                    self = .orientation(op, orientations)
                case .screenSize:
                    let op = try container.decode(ArrayOperatorType.self, forKey: .operator)
                    let sizes = try container.decode([String].self, forKey: .screenSize)
                    self = .screenSize(op, sizes)
                case .selectedPackage:
                    self = .selectedPackage
                case .introOffer:
                    self = .introOffer
                case .promoOffer:
                    self = .promoOffer
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
            case screenSize
            case `operator`
            case orientations

        }

        // swiftlint:disable:next nesting
        private enum ConditionType: String, Decodable {

            case orientation = "orientation"
            case screenSize = "screen_size"
            case selectedPackage = "selected_package"
            case introOffer = "intro_offer"
            case promoOffer = "promo_offer"
            case selected

        }

        public enum ArrayOperatorType: String, Codable, Sendable, Hashable, Equatable {

            case `in` = "in"
            case notIn = "not_in"

        }

        public enum EqualityOperatorType: String, Codable, Sendable, Hashable, Equatable {

            case `equals` = "="
            case notEquals = "!="

        }

        public enum OrientationType: String, Codable, Sendable, Hashable, Equatable {

            case portrait = "portrait"
            case landscape = "landscape"

        }

    }

}
