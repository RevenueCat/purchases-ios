//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallVariableUpdate.swift
//
//  Created for paywall state management.
//
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public extension PaywallComponent {

    /// A declarative variable-store mutation applied when an interactive component's primary event fires.
    ///
    /// JSON shape (current operations):
    /// ```
    /// { "set": "variable_name", "to": <literal value | "$value"> }
    /// ```
    ///
    /// The `"$value"` token instructs the runtime to substitute the interaction's payload
    /// (e.g. selected tab id, carousel destination page index, selected package id).
    /// Unknown shapes decode as `.unsupported` so newer JSON remains safe on older SDKs.
    enum VariableUpdate: Codable, Sendable, Hashable, Equatable {

        case set(key: String, value: VariableUpdateValue)

        /// Fallback for variable-update shapes this SDK version does not understand.
        case unsupported

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case set
            case to
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let key = try container.decodeIfPresent(String.self, forKey: .set) {
                let value = try container.decode(VariableUpdateValue.self, forKey: .to)
                self = .set(key: key, value: value)
                return
            }
            self = .unsupported
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .set(let key, let value):
                try container.encode(key, forKey: .set)
                try container.encode(value, forKey: .to)
            case .unsupported:
                break
            }
        }

    }

    /// The value of a `VariableUpdate.set` operation. Either a literal `ConditionValue` or a reference
    /// to the firing component's interaction payload (`"$value"` in JSON).
    enum VariableUpdateValue: Codable, Sendable, Hashable, Equatable {

        case literal(ConditionValue)
        case payloadReference

        /// The reserved JSON string indicating the value should be taken from the interaction's payload.
        public static let payloadReferenceToken: String = "$value"

        public init(from decoder: Decoder) throws {
            let conditionValue = try ConditionValue(from: decoder)
            if case .string(let str) = conditionValue, str == VariableUpdateValue.payloadReferenceToken {
                self = .payloadReference
            } else {
                self = .literal(conditionValue)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .literal(let value):
                try container.encode(value)
            case .payloadReference:
                try container.encode(VariableUpdateValue.payloadReferenceToken)
            }
        }

    }

}
