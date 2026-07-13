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

@_spi(Internal) public protocol PaywallPartialComponent: PaywallComponentBase {}

// MARK: - Public Types

@_spi(Internal) public extension PaywallComponent {

    typealias ComponentOverrides<T: PaywallPartialComponent> = [ComponentOverride<T>]

    struct ComponentOverride<T: PaywallPartialComponent>: Codable, Sendable, Hashable, Equatable {

        public var conditions: [Condition] {
            extendedConditions.map { $0.toCondition() }
        }
        public let properties: T

        /// Internal storage for extended conditions with full type information
        @_spi(Internal) public let extendedConditions: [ExtendedCondition]

        public init(conditions: [Condition], properties: T) {
            self.extendedConditions = conditions.map { ExtendedCondition(from: $0) }
            self.properties = properties
        }

        @_spi(Internal)
        public init(extendedConditions: [ExtendedCondition], properties: T) {
            self.extendedConditions = extendedConditions
            self.properties = properties
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.extendedConditions = try container.decode([ExtendedCondition].self, forKey: .conditions)
            self.properties = try container.decode(T.self, forKey: .properties)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(extendedConditions, forKey: .conditions)
            try container.encode(properties, forKey: .properties)
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case conditions
            case properties
        }

    }

    /// Public condition type for component overrides.
    /// New condition types not recognized by this SDK version will decode as `.unsupported`.
    ///
    /// `ComponentOverride` decodes conditions as `ExtendedCondition` internally
    /// and exposes them via `toCondition()`. This enum is not directly decoded from JSON.
    enum Condition: String, Codable, Sendable, Hashable, Equatable {

        case compact
        case medium
        case expanded
        case introOffer = "intro_offer"
        case promoOffer = "promo_offer"
        case selected
        case unsupported

    }

}

// MARK: - Internal Types for Extended Condition Support

@_spi(Internal)
extension PaywallComponent {

    /// Value type for condition comparisons, supporting string, number, and boolean values.
    @_spi(Internal)
    public enum ConditionValue: Codable, Sendable, Hashable, Equatable {

        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            // Try bool first (could be decoded as number), then int, double, string
            if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
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
            case .int(let value):
                try container.encode(value)
            case .double(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            }
        }

    }

    /// Equality operators for condition evaluation (=, !=).
    @_spi(Internal)
    public enum EqualityOperator: String, Codable, Sendable, Hashable, Equatable {

        case equals = "="
        case notEquals = "!="

    }

    /// Array operators for condition evaluation (in, not in).
    @_spi(Internal)
    public enum ArrayOperator: String, Codable, Sendable, Hashable, Equatable {

        // swiftlint:disable:next identifier_name
        case `in` = "in"
        case notIn = "not in"

    }

    /// Internal condition type that preserves full type information including associated values.
    /// This is used internally for condition evaluation while the public `Condition` type
    /// maintains API stability.
    @_spi(Internal) public enum ExtendedCondition: Codable, Sendable, Hashable, Equatable {

        // MARK: - Screen size conditions (legacy)
        case compact
        case medium
        case expanded

        // MARK: - Selection state
        case selected

        // MARK: - Offer eligibility (legacy simple boolean check)
        case introOffer
        case promoOffer

        // MARK: - Offer eligibility (with operator/value)
        case introOfferCondition(operator: EqualityOperator, value: Bool)
        case promoOfferCondition(operator: EqualityOperator, value: Bool)

        // Multiple intro offers condition - supported in Android, always evaluates to false on iOS
        case multipleIntroOffers

        // MARK: - V0 Conditional configurability conditions
        case variable(operator: EqualityOperator, variable: String, value: ConditionValue)
        case selectedPackage(operator: ArrayOperator, packages: [String])

        // MARK: - Paywall component state (state-driven paywalls)
        case state(operator: EqualityOperator, name: String, value: ConditionValue)

        // MARK: - Fallback for unknown conditions
        case unsupported

        /// Whether this condition is a rule introduced by conditional configurability
        /// (e.g., variable_condition, selected_package_condition, intro_offer_condition, promo_offer_condition).
        /// When an unsupported condition is encountered, all overrides containing rules are discarded,
        /// rendering the "default paywall" with only base conditions applied.
        /// Note: `.unsupported` is NOT a rule — it existed before conditional configurability as a
        /// fallback for unrecognized condition types. It always evaluates to `false` at runtime.
        @_spi(Internal) public var isRule: Bool {
            switch self {
            case .compact, .medium, .expanded, .selected, .introOffer, .promoOffer,
                 .multipleIntroOffers, .unsupported:
                return false
            case .introOfferCondition, .promoOfferCondition, .variable, .selectedPackage, .state:
                return true
            }
        }

        /// Converts to the public Condition type.
        /// Extended conditions that cannot be represented in the public type return `.unsupported`.
        public func toCondition() -> Condition {
            switch self {
            case .compact: return .compact
            case .medium: return .medium
            case .expanded: return .expanded
            case .selected: return .selected
            case .introOffer, .introOfferCondition: return .introOffer
            case .promoOffer, .promoOfferCondition: return .promoOffer
            case .multipleIntroOffers, .variable, .selectedPackage, .state, .unsupported: return .unsupported
            }
        }

        /// Creates an ExtendedCondition from a public Condition.
        /// Legacy intro/promo offer conditions are normalized to the extended form.
        public init(from condition: Condition) {
            switch condition {
            case .compact: self = .compact
            case .medium: self = .medium
            case .expanded: self = .expanded
            case .selected: self = .selected
            case .introOffer: self = .introOffer
            case .promoOffer: self = .promoOffer
            case .unsupported: self = .unsupported
            }
        }

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
            case .selected:
                try container.encode(ConditionType.selected.rawValue, forKey: .type)
            case .introOffer:
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
            case .promoOffer:
                try container.encode(ConditionType.promoOffer.rawValue, forKey: .type)
            case .introOfferCondition(let condOp, let value):
                try container.encode(ConditionType.introOfferCondition.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(value, forKey: .value)
            case .promoOfferCondition(let condOp, let value):
                try container.encode(ConditionType.promoOfferCondition.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(value, forKey: .value)
            case .multipleIntroOffers:
                try container.encode(ConditionType.multipleIntroOffers.rawValue, forKey: .type)
            case .variable(let condOp, let variable, let value):
                try container.encode(ConditionType.variableCondition.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(variable, forKey: .variable)
                try container.encode(value, forKey: .value)
            case .selectedPackage(let condOp, let packages):
                try container.encode(ConditionType.selectedPackageCondition.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(packages, forKey: .packages)
            case .state(let condOp, let name, let value):
                try container.encode(ConditionType.stateCondition.rawValue, forKey: .type)
                try container.encode(condOp, forKey: .operator)
                try container.encode(name, forKey: .name)
                try container.encode(value, forKey: .value)
            case .unsupported:
                try container.encode("unsupported", forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            do {
                self = try Self.decodeCondition(from: decoder)
            } catch {
                let rawType = (try? decoder.container(keyedBy: CodingKeys.self)
                    .decode(String.self, forKey: .type)) ?? "unknown"
                Logger.warn(Strings.paywalls.malformed_condition(rawType, error))
                self = .unsupported
            }
        }

        // swiftlint:disable:next cyclomatic_complexity
        private static func decodeCondition(from decoder: Decoder) throws -> Self {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .type)

            guard let conditionType = ConditionType(rawValue: rawValue) else {
                Logger.warn(Strings.paywalls.unrecognized_condition_type(rawValue))
                return .unsupported
            }

            switch conditionType {
            case .compact:
                return .compact
            case .medium:
                return .medium
            case .expanded:
                return .expanded
            case .selected:
                return .selected
            case .introOffer:
                return .introOffer
            case .introOfferCondition:
                let condOp = try container.decode(EqualityOperator.self, forKey: .operator)
                let value = try container.decode(Bool.self, forKey: .value)
                return .introOfferCondition(operator: condOp, value: value)
            case .promoOffer:
                return .promoOffer
            case .promoOfferCondition:
                let condOp = try container.decode(EqualityOperator.self, forKey: .operator)
                let value = try container.decode(Bool.self, forKey: .value)
                return .promoOfferCondition(operator: condOp, value: value)
            case .multipleIntroOffers:
                return .multipleIntroOffers
            case .variableCondition:
                let condOp = try container.decode(EqualityOperator.self, forKey: .operator)
                let variable = try container.decode(String.self, forKey: .variable)
                let value = try container.decode(ConditionValue.self, forKey: .value)
                return .variable(operator: condOp, variable: variable, value: value)
            case .selectedPackageCondition:
                let condOp = try container.decode(ArrayOperator.self, forKey: .operator)
                let packages = try container.decode([String].self, forKey: .packages)
                return .selectedPackage(operator: condOp, packages: packages)
            case .stateCondition:
                let condOp = try container.decode(EqualityOperator.self, forKey: .operator)
                let name = try container.decode(String.self, forKey: .name)
                let value = try container.decode(ConditionValue.self, forKey: .value)
                return .state(operator: condOp, name: name, value: value)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case `operator`
            case value
            case variable
            case packages
            case name

        }

        // swiftlint:disable:next nesting
        private enum ConditionType: String {

            case compact
            case medium
            case expanded
            case introOffer = "intro_offer"
            case introOfferCondition = "intro_offer_condition"
            case promoOffer = "promo_offer"
            case promoOfferCondition = "promo_offer_condition"
            case multipleIntroOffers = "multiple_intro_offers"
            case selected
            case variableCondition = "variable_condition"
            case selectedPackageCondition = "selected_package_condition"
            case stateCondition = "state_condition"

        }

    }

}
