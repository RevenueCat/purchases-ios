//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewValue.swift

import Foundation

#if !os(tvOS) // For Paywalls V2

/// A JSON-compatible value exchanged between a Paywalls V2 `web_view` component and your app.
///
/// Values mirror the JSON types allowed by the web view message protocol: strings, numbers,
/// booleans, arrays, objects, and null. Functions, binary data, dates, and other platform-specific
/// objects are not representable.
///
/// Modeled as a `struct` wrapping a private storage type (rather than an `enum`) so that adding new
/// representable types in the future is not a source-breaking change for consumers.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct PaywallWebViewValue: Sendable, Equatable, Hashable {

    private indirect enum Storage: Sendable, Equatable, Hashable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case array([PaywallWebViewValue])
        case object([String: PaywallWebViewValue])
        case null
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    /// Creates a string value.
    public static func string(_ value: String) -> PaywallWebViewValue {
        PaywallWebViewValue(.string(value))
    }

    /// Creates a numeric value.
    public static func number(_ value: Double) -> PaywallWebViewValue {
        PaywallWebViewValue(.number(value))
    }

    /// Creates a boolean value.
    public static func bool(_ value: Bool) -> PaywallWebViewValue {
        PaywallWebViewValue(.bool(value))
    }

    /// Creates an array value.
    public static func array(_ value: [PaywallWebViewValue]) -> PaywallWebViewValue {
        PaywallWebViewValue(.array(value))
    }

    /// Creates an object (dictionary) value.
    public static func object(_ value: [String: PaywallWebViewValue]) -> PaywallWebViewValue {
        PaywallWebViewValue(.object(value))
    }

    /// A null value.
    public static let null = PaywallWebViewValue(.null)

    // MARK: - Accessors

    /// The string payload if this value was created as a string, otherwise `nil`.
    public var stringValue: String? {
        if case .string(let value) = self.storage { return value }
        return nil
    }

    /// The numeric payload if this value was created as a number, otherwise `nil`.
    public var numberValue: Double? {
        if case .number(let value) = self.storage { return value }
        return nil
    }

    /// The boolean payload if this value was created as a boolean, otherwise `nil`.
    public var boolValue: Bool? {
        if case .bool(let value) = self.storage { return value }
        return nil
    }

    /// The array payload if this value was created as an array, otherwise `nil`.
    public var arrayValue: [PaywallWebViewValue]? {
        if case .array(let value) = self.storage { return value }
        return nil
    }

    /// The object payload if this value was created as an object, otherwise `nil`.
    public var objectValue: [String: PaywallWebViewValue]? {
        if case .object(let value) = self.storage { return value }
        return nil
    }

    /// Whether this value is null.
    public var isNull: Bool {
        if case .null = self.storage { return true }
        return false
    }

}

// MARK: - Foundation / JSON bridging

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallWebViewValue {

    /// The maximum nesting depth allowed when converting a JSON object tree. Mirrors the limit
    /// enforced by the message parser so that conversion and validation agree.
    static let maxDepth = 32

    /// Creates a value from a Foundation JSON object (as produced by `WKScriptMessage.body` or
    /// `JSONSerialization`). Returns `nil` if the object contains any non-JSON value or exceeds
    /// ``maxDepth``.
    ///
    /// Boolean `NSNumber`s are disambiguated from numeric `NSNumber`s so JavaScript `true`/`false`
    /// map to ``bool(_:)`` rather than ``number(_:)``.
    init?(jsonObject: Any, depth: Int = 0) {
        guard depth <= Self.maxDepth else { return nil }

        switch jsonObject {
        case is NSNull:
            self = .null

        case let number as NSNumber:
            // `NSNumber` wrapping a `Bool` is bridged distinctly from numeric values.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else {
                self = .number(number.doubleValue)
            }

        case let string as String:
            self = .string(string)

        case let array as [Any]:
            guard let converted = Self.convert(array: array, depth: depth) else { return nil }
            self = .array(converted)

        case let object as [String: Any]:
            guard let converted = Self.convert(object: object, depth: depth) else { return nil }
            self = .object(converted)

        default:
            // Dates, binary blobs, functions, and any other non-JSON type are rejected.
            return nil
        }
    }

    private static func convert(array: [Any], depth: Int) -> [PaywallWebViewValue]? {
        var converted: [PaywallWebViewValue] = []
        converted.reserveCapacity(array.count)
        for element in array {
            guard let value = PaywallWebViewValue(jsonObject: element, depth: depth + 1) else {
                return nil
            }
            converted.append(value)
        }
        return converted
    }

    private static func convert(object: [String: Any], depth: Int) -> [String: PaywallWebViewValue]? {
        var converted: [String: PaywallWebViewValue] = [:]
        converted.reserveCapacity(object.count)
        for (key, element) in object {
            guard let value = PaywallWebViewValue(jsonObject: element, depth: depth + 1) else {
                return nil
            }
            converted[key] = value
        }
        return converted
    }

    /// A Foundation representation suitable for `JSONSerialization`.
    var jsonObject: Any {
        switch self.storage {
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value
        case .array(let values):
            return values.map { $0.jsonObject }
        case .object(let values):
            return values.mapValues { $0.jsonObject }
        case .null:
            return NSNull()
        }
    }

}

#endif
