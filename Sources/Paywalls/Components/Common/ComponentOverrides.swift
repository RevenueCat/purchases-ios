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

        /// Compares that the selected package against [value]
        case selectedPackage(ArrayOperatorType, [String])

        /// Compares the selected package's intro-offer eligibility (not the whole paywall) against [value].
        /// This matches the package the customer currently has highlighted in the UI.
        case introOffer(EqualityOperatorType, Bool)

        /// Compares against whether any package on the paywall has an intro offer.
        case anyPackageContainsIntroOffer(EqualityOperatorType, Bool)

        /// Compares the selected package's promo-offer eligibility (not the whole paywall) against [value].
        /// This matches the package the customer currently has highlighted in the UI.
        case promoOffer(EqualityOperatorType, Bool)

        /// Compares against whether any package on the paywall has a promo offer.
        case anyPackageContainsPromoOffer(EqualityOperatorType, Bool)

        /// Is the current component selected?
        case selected

        /// Compares the app version (as integer with dots removed) against [value]
        case appVersion(ComparisonOperatorType, Int)

        // For unknown cases
        case unsupported

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .orientation(let operand, let orientations):
                try container.encode(ConditionType.orientation.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(orientations, forKey: .orientations)
            case .screenSize(let operand, let screenSizes):
                try container.encode(ConditionType.screenSize.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(screenSizes, forKey: .sizes)
            case let .selectedPackage(operand, packages):
                try container.encode(ConditionType.selectedPackage.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(packages, forKey: .packages)
            case let .introOffer(operand, value):
                try container.encode(ConditionType.introOffer.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(value, forKey: .value)
            case let .anyPackageContainsIntroOffer(operand, value):
                try container.encode(ConditionType.anyPackageContainsIntroOffer.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(value, forKey: .value)
            case let .promoOffer(operand, value):
                try container.encode(ConditionType.promoOffer.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(value, forKey: .value)
            case let .anyPackageContainsPromoOffer(operand, value):
                try container.encode(ConditionType.anyPackageContainsPromoOffer.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(value, forKey: .value)
            case .selected:
                try container.encode(ConditionType.selected.rawValue, forKey: .type)
            case let .appVersion(operand, value):
                try container.encode(ConditionType.appVersion.rawValue, forKey: .type)
                try container.encode(operand, forKey: .operator)
                try container.encode(String(value), forKey: .value)
            case .unsupported:
                // Encode a default value for unsupported
                try container.encode("unknown", forKey: .type)
            }
        }

        // swiftlint:disable:next cyclomatic_complexity
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .type)

            if let conditionType = ConditionType(rawValue: rawValue) {
                switch conditionType {
                case .orientation:
                    let operand = try container.decode(ArrayOperatorType.self, forKey: .operator)
                    let orientations = try container.decode([OrientationType].self, forKey: .orientations)
                    self = .orientation(operand, orientations)
                case .screenSize:
                    let operand = try container.decode(ArrayOperatorType.self, forKey: .operator)
                    let sizes = try container.decode([String].self, forKey: .sizes)
                    self = .screenSize(operand, sizes)
                case .selectedPackage:
                    let operand = try container.decode(ArrayOperatorType.self, forKey: .operator)
                    let packages = try container.decode([String].self, forKey: .packages)
                    self = .selectedPackage(operand, packages)
                case .introOffer:
                    let operand = try container.decodeIfPresent(EqualityOperatorType.self, forKey: .operator) ?? .equals
                    let value = try container.decodeIfPresent(Bool.self, forKey: .value) ?? true
                    self = .introOffer(operand, value)
                case .anyPackageContainsIntroOffer:
                    let operand = try container.decode(EqualityOperatorType.self, forKey: .operator)
                    let value = try container.decode(Bool.self, forKey: .value)
                    self = .anyPackageContainsIntroOffer(operand, value)
                case .promoOffer:
                    let operand = try container.decode(EqualityOperatorType.self, forKey: .operator)
                    let value = try container.decode(Bool.self, forKey: .value)
                    self = .promoOffer(operand, value)
                case .anyPackageContainsPromoOffer:
                    let operand = try container.decode(EqualityOperatorType.self, forKey: .operator)
                    let value = try container.decode(Bool.self, forKey: .value)
                    self = .anyPackageContainsPromoOffer(operand, value)
                case .selected:
                    self = .selected
                case .appVersion:
                    let operand = try container.decode(ComparisonOperatorType.self, forKey: .operator)
                    let versionString = try container.decode(String.self, forKey: .value)
                    if let versionInt = SystemInfo.appVersion.extractNumber() {
                        self = .appVersion(operand, versionInt)
                    } else {
                        self = .unsupported
                    }
                }
            } else {
                self = .unsupported
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case sizes
            case `operator`
            case orientations
            case packages
            case value

        }

        // swiftlint:disable:next nesting
        private enum ConditionType: String, Decodable {

            case orientation = "orientation"
            case screenSize = "screen_size"
            case selectedPackage = "selected_package"
            case introOffer = "intro_offer"
            case anyPackageContainsIntroOffer = "introductory_offer_available"
            case promoOffer = "promo_offer"
            case anyPackageContainsPromoOffer = "promo_offer_available"
            case selected
            case appVersion = "app_version"

        }

        // swiftlint:disable:next nesting
        public enum ArrayOperatorType: String, Codable, Sendable, Hashable, Equatable {

            // swiftlint:disable:next identifier_name
            case `in` = "in"
            case notIn = "not_in"

        }

        // swiftlint:disable:next nesting
        public enum EqualityOperatorType: String, Codable, Sendable, Hashable, Equatable {

            case `equals` = "="
            case notEquals = "!="

        }

        // swiftlint:disable:next nesting
        public enum ComparisonOperatorType: String, Codable, Sendable, Hashable, Equatable {

            case lessThan = "<"
            case lessThanOrEqual = "<="
            case equal = "="
            case greaterThan = ">"
            case greaterThanOrEqual = ">="

        }

        // swiftlint:disable:next nesting
        public enum OrientationType: String, Codable, Sendable, Hashable, Equatable {

            case portrait
            case landscape

        }

    }

}
