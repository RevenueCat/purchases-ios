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
