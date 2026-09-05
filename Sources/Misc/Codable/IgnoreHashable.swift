//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IgnoreHashable.swift
//
//  Created by Nacho Soto on 5/24/22.

import Foundation

/// A property wrapper that allows ignoring a value from the `Hashable` / `Equatable` implementation
/// - Example:
/// ```
/// struct Data {
///     var string1: String // Data equality / hash only uses this value
///     @IgnoreHashable var string2: String
/// }
/// ```
@propertyWrapper
struct IgnoreHashable<Value> {

    var wrappedValue: Value

}

extension IgnoreHashable: Hashable {

    static func == (lhs: Self, rhs: Self) -> Bool { return true }

    func hash(into hasher: inout Hasher) {}

}

extension IgnoreHashable: Decodable where Value: Decodable {

    init(from decoder: Decoder) throws {
        self.init(wrappedValue: try .init(from: decoder))
    }

}

extension IgnoreHashable: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension KeyedEncodingContainer {

    /// A wrapped optional that is absent stays absent, rather than being written out as an
    /// explicit null the way the synthesized `encode` would.
    mutating func encode<Value: Encodable>(
        _ value: IgnoreHashable<Value?>,
        forKey key: Key
    ) throws {
        try self.encodeIfPresent(value.wrappedValue, forKey: key)
    }

}

extension KeyedDecodingContainer {

    /// A wrapped optional still has to survive its key being absent, which the synthesized
    /// `decode` does not do once the property's type is the wrapper rather than the optional.
    func decode<Value: Decodable>(
        _ type: IgnoreHashable<Value?>.Type,
        forKey key: Key
    ) throws -> IgnoreHashable<Value?> {
        return try self.decodeIfPresent(type, forKey: key) ?? .init(wrappedValue: nil)
    }

}
