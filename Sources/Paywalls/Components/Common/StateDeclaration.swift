//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StateDeclaration.swift
//
// swiftlint:disable missing_docs nesting

import Foundation

@_spi(Internal) public extension PaywallComponent {

    /// Declares a named paywall state key: its value type and the default the state store is seeded with.
    ///
    /// JSON shape (an entry of the top-level `state` map):
    /// ```
    /// "<key>": { "type": "boolean" | "integer" | "double" | "string", "default": <value> }
    /// ```
    ///
    /// The `type` is kept as an opaque string so future types decode without failing;
    /// keys themselves are opaque, editor-generated identifiers the SDK never derives or transforms.
    struct StateDeclaration: Codable, Sendable, Hashable, Equatable {

        /// Known wire values for ``type``. Caseless namespace: forward-compatible with future types.
        @_spi(Internal) public enum ValueType {
            public static let boolean = "boolean"
            public static let integer = "integer"
            public static let double = "double"
            public static let string = "string"
        }

        /// The declared value type. One of `boolean`, `integer`, `double`, or `string`;
        /// unknown values are preserved as-is for forward compatibility.
        public let type: String

        /// The value the state store holds for this key until a state update writes to it.
        public let defaultValue: ConditionValue

        /// The declared default, coerced to the declared `type` where the JSON literal is ambiguous
        /// (e.g. a `double`-typed key whose default was authored as `0` decodes as an int literal).
        public var normalizedDefaultValue: ConditionValue {
            if self.type == ValueType.double, case .int(let intValue) = self.defaultValue {
                return .double(Double(intValue))
            }
            return self.defaultValue
        }

        public init(type: String, defaultValue: ConditionValue) {
            self.type = type
            self.defaultValue = defaultValue
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case defaultValue = "default"
        }

    }

}
