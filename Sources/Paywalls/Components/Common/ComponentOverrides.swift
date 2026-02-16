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

    /// Value type for condition comparisons, supporting string, number, and boolean values.
    enum ConditionValue: Codable, Sendable, Hashable, Equatable {

        case string(String)
        case number(Double)
        case bool(Bool)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            // Try decoding in order: bool first (since it could be decoded as number), then number, then string
            if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .number(doubleValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(
                    ConditionValue.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected string, number, or boolean value"
                    )
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            }
        }

        /// String representation for comparison purposes.
        public var stringValue: String {
            switch self {
            case .string(let value):
                return value
            case .number(let value):
                if value.truncatingRemainder(dividingBy: 1) == 0 {
                    return String(format: "%.0f", value)
                }
                return String(value)
            case .bool(let value):
                return value ? "true" : "false"
            }
        }

    }

    /// Operators used in condition evaluation.
    enum ConditionOperator: String, Codable, Sendable, Hashable, Equatable {

        case equals = "="
        case notEquals = "!="
        // swiftlint:disable:next identifier_name
        case `in` = "in"
        case notIn = "not in"

    }

    enum Condition: Codable, Sendable, Hashable, Equatable {

        // MARK: - Screen size conditions (legacy)
        case compact
        case medium
        case expanded

        // MARK: - Selection state
        case selected

        // MARK: - Offer eligibility (legacy - no operator/value)
        case introOffer
        case promoOffer

        // MARK: - Extended offer eligibility (with operator/value)
        case introOfferCondition(operator: ConditionOperator, value: Bool)
        case promoOfferCondition(operator: ConditionOperator, value: Bool)

        // MARK: - V0 Conditional configurability conditions
        case variableCondition(operator: ConditionOperator, variable: String, value: ConditionValue)
        case packageCondition(operator: ConditionOperator, packageId: String)
        case selectedPackageCondition(operator: ConditionOperator, packages: [String])

        // MARK: - Fallback for unknown conditions
        case unsupported

        // swiftlint:disable:next cyclomatic_complexity
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .compact:
                try container.encode(ConditionType.compact.rawValue, forKey: .type)
            case .medium:
                try container.encode(ConditionType.medium.rawValue, forKey: .type)
            case .expanded:
                try container.encode(ConditionType.expanded.rawValue, forKey: .type)
            case .introOffer:
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
            case .promoOffer:
                try container.encode(ConditionType.promoOffer.rawValue, forKey: .type)
            case .selected:
                try container.encode(ConditionType.selected.rawValue, forKey: .type)
            case .introOfferCondition(let condOp, let value):
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(value, forKey: .value)
            case .promoOfferCondition(let condOp, let value):
                try container.encode(ConditionType.promoOffer.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(value, forKey: .value)
            case .variableCondition(let condOp, let variable, let value):
                try container.encode(ConditionType.variable.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(variable, forKey: .variable)
                try container.encode(value, forKey: .value)
            case .packageCondition(let condOp, let packageId):
                try container.encode(ConditionType.package.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(packageId, forKey: .packageId)
            case .selectedPackageCondition(let condOp, let packages):
                try container.encode(ConditionType.selectedPackage.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(packages, forKey: .packages)
            case .unsupported:
                try container.encode("unsupported", forKey: .type)
            }
        }

        // swiftlint:disable:next cyclomatic_complexity
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .type)

            guard let conditionType = ConditionType(rawValue: rawValue) else {
                self = .unsupported
                return
            }

            do {
                switch conditionType {
                case .compact:
                    self = .compact
                case .medium:
                    self = .medium
                case .expanded:
                    self = .expanded
                case .selected:
                    self = .selected
                case .introOffer:
                    // Check for extended form (with operator/value)
                    if let condOp = try container.decodeIfPresent(ConditionOperator.self, forKey: .operator),
                       let value = try container.decodeIfPresent(Bool.self, forKey: .value) {
                        self = .introOfferCondition(operator: condOp, value: value)
                    } else {
                        // Legacy form (no operator/value)
                        self = .introOffer
                    }
                case .promoOffer:
                    // Check for extended form (with operator/value)
                    if let condOp = try container.decodeIfPresent(ConditionOperator.self, forKey: .operator),
                       let value = try container.decodeIfPresent(Bool.self, forKey: .value) {
                        self = .promoOfferCondition(operator: condOp, value: value)
                    } else {
                        // Legacy form (no operator/value)
                        self = .promoOffer
                    }
                case .variable:
                    let condOp = try container.decode(ConditionOperator.self, forKey: .operator)
                    let variable = try container.decode(String.self, forKey: .variable)
                    let value = try container.decode(ConditionValue.self, forKey: .value)
                    self = .variableCondition(operator: condOp, variable: variable, value: value)
                case .package:
                    let condOp = try container.decode(ConditionOperator.self, forKey: .operator)
                    let packageId = try container.decode(String.self, forKey: .packageId)
                    self = .packageCondition(operator: condOp, packageId: packageId)
                case .selectedPackage:
                    let condOp = try container.decode(ConditionOperator.self, forKey: .operator)
                    let packages = try container.decode([String].self, forKey: .packages)
                    self = .selectedPackageCondition(operator: condOp, packages: packages)
                }
            } catch {
                // If decoding fails for a known type (e.g., malformed value), fall back to unsupported
                self = .unsupported
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case `operator`
            case value
            case variable
            case packageId = "package_id"
            case packages

        }

        // swiftlint:disable:next nesting
        private enum ConditionType: String {

            case compact
            case medium
            case expanded
            case introOffer = "intro_offer"
            case promoOffer = "promo_offer"
            case selected
            case variable
            case package
            case selectedPackage = "selected_package"

        }

    }

}
