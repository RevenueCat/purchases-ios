//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoints.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// A custom value supplied when a checkpoint is hit.
///
/// This is a closed set because checkpoint properties support JSON primitive values only. Unlike checkpoint results,
/// adding arbitrary result variants is not part of this type's extensibility contract.
@_spi(Internal)
public enum CheckpointValue: Equatable, Hashable, Sendable {

    // swiftlint:disable missing_docs
    case string(String)
    case integer(Int64)
    case double(Double)
    case boolean(Bool)
    // swiftlint:enable missing_docs

}

extension CheckpointValue: ExpressibleByStringLiteral {

    /// Creates a string checkpoint value from a string literal.
    public init(stringLiteral value: String) { self = .string(value) }

}

extension CheckpointValue: ExpressibleByIntegerLiteral {

    /// Creates an integer checkpoint value from an integer literal.
    public init(integerLiteral value: Int64) { self = .integer(value) }

}

extension CheckpointValue: ExpressibleByFloatLiteral {

    /// Creates a floating-point checkpoint value from a floating-point literal.
    public init(floatLiteral value: Double) { self = .double(value) }

}

extension CheckpointValue: ExpressibleByBooleanLiteral {

    /// Creates a Boolean checkpoint value from a Boolean literal.
    public init(booleanLiteral value: Bool) { self = .boolean(value) }

}

extension CheckpointValue: Codable {

    /// Creates a checkpoint value by decoding a primitive JSON value.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a string, integer, double, or boolean."
                )
            )
        }
    }

    /// Encodes the checkpoint value as a primitive JSON value.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value): try container.encode(value)
        case let .integer(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .boolean(value): try container.encode(value)
        }
    }

}

extension CheckpointValue {

    /// Creates a checkpoint value from a supported Foundation primitive.
    public init?(foundationValue: Any) {
        if let value = foundationValue as? String {
            self = .string(value)
            return
        }

        guard let number = foundationValue as? NSNumber else { return nil }
        switch number.jsonNumberKind {
        case .boolean:
            self = .boolean(number.boolValue)
        case .integer:
            guard let value = Int64(number.stringValue) else { return nil }
            self = .integer(value)
        case .floatingPoint:
            self = .double(number.doubleValue)
        }
    }

    /// The equivalent Foundation primitive value.
    public var foundationValue: Any {
        switch self {
        case let .string(value): return value
        case let .integer(value): return NSNumber(value: value)
        case let .double(value): return NSNumber(value: value)
        case let .boolean(value): return NSNumber(value: value)
        }
    }

}

extension CheckpointValue {

    var dimensionValue: DimensionValue {
        switch self {
        case let .string(value): return .string(value)
        case let .integer(value): return .int(value)
        case let .double(value): return .double(value)
        case let .boolean(value): return .bool(value)
        }
    }

}

/// Per-call parameters for a checkpoint.
@_spi(Internal)
public final class CheckpointParams: Equatable, Hashable, CustomStringConvertible, @unchecked Sendable {

    /// Custom variables usable in checkpoint targeting rules and feature events.
    public let customVariables: [String: CheckpointValue]

    /// Creates checkpoint parameters with the supplied custom variables.
    public init(customVariables: [String: CheckpointValue] = [:]) {
        self.customVariables = customVariables
    }

    /// Returns whether two parameter collections contain the same custom variables.
    public static func == (lhs: CheckpointParams, rhs: CheckpointParams) -> Bool {
        return lhs.customVariables == rhs.customVariables
    }

    /// Hashes the checkpoint parameters.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.customVariables)
    }

    /// A debug description of the checkpoint parameters.
    public var description: String {
        return "CheckpointParams(customVariables=\(self.customVariables))"
    }

}
