//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoint.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// A custom value supplied when a checkpoint is hit.
///
/// This is a closed set because checkpoint properties support JSON primitive values only. Unlike checkpoint results,
/// adding arbitrary result variants is not part of this type's extensibility contract.
@_spi(Internal) public enum CheckpointValue: Equatable, Hashable, Sendable {

    /// A string value.
    case string(String)
    /// An integer value.
    case integer(Int64)
    /// A floating-point value.
    case double(Double)
    /// A Boolean value.
    case boolean(Bool)

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

/// Per-call parameters for a checkpoint.
#if ENABLE_CHECKPOINTS_OBJC
@objc(RCCheckpointParams)
#endif
@_spi(Internal) public final class CheckpointParams: NSObject, @unchecked Sendable {

    /// Custom properties usable in checkpoint targeting rules and feature events.
    public let customProperties: [String: CheckpointValue]

    /// Creates checkpoint parameters with the supplied custom properties.
    public init(customProperties: [String: CheckpointValue] = [:]) {
        self.customProperties = customProperties
        super.init()
    }

#if ENABLE_CHECKPOINTS_OBJC
    /// Creates checkpoint parameters from Objective-C Foundation primitive values. Unsupported values are dropped.
    @objc(initWithCustomProperties:)
    public convenience init(objcCustomProperties: NSDictionary) {
        var values: [String: CheckpointValue] = [:]
        for (rawKey, rawValue) in objcCustomProperties {
            guard let key = rawKey as? String,
                  let value = CheckpointValue(foundationValue: rawValue) else {
                Logger.warn(CheckpointStrings.invalidObjectiveCCustomProperty(type(of: rawValue)))
                continue
            }
            values[key] = value
        }
        self.init(customProperties: values)
    }

    /// The custom properties as Objective-C Foundation primitive values.
    @objc(customProperties)
    public var objcCustomProperties: NSDictionary {
        return self.customProperties.mapValues { $0.foundationValue } as NSDictionary
    }
#endif

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CheckpointParams else { return false }
        return self.customProperties == other.customProperties
    }

    public override var hash: Int { return self.customProperties.hashValue }

    /// A debug description of the checkpoint parameters.
    public override var description: String {
        return "CheckpointParams(customProperties=\(self.customProperties))"
    }

}

private enum CheckpointStrings: LogMessage {

    case invalidObjectiveCCustomProperty(Any.Type)

    var description: String {
        switch self {
        case let .invalidObjectiveCCustomProperty(type):
            return "Dropping invalid Objective-C checkpoint custom property: \(String(reflecting: type))"
        }
    }

    var category: String { return "checkpoints" }

}
