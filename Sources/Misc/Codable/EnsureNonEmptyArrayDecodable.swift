//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EnsureNonEmptyArrayDecodable.swift
//
//  Created by Nacho Soto on 7/17/23.

import Foundation

/// A property wrapper that ensures decoded arrays aren't empty.
/// - Example:
/// ```
/// struct Data {
///     @EnsureNonEmptyArrayDecodable var values: [String] // fails to decode if array is empty
/// }
/// ```
@propertyWrapper
struct EnsureNonEmptyArrayDecodable<Value: Codable> {

    struct Error: Swift.Error {}

    var wrappedValue: [Value]

}

extension EnsureNonEmptyArrayDecodable: Equatable where Value: Equatable {}
extension EnsureNonEmptyArrayDecodable: Hashable where Value: Hashable {}

extension EnsureNonEmptyArrayDecodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Value].self)

        if array.isEmpty {
            throw Error()
        } else {
            self.wrappedValue = array
        }
    }

}

extension EnsureNonEmptyArrayDecodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension KeyedDecodingContainer {

    func decode<T>(
        _ type: EnsureNonEmptyArrayDecodable<T>.Type,
        forKey key: Key
    ) throws -> EnsureNonEmptyArrayDecodable<T> {
        return try self.decodeIfPresent(type, forKey: key)
            .orThrow(EnsureNonEmptyArrayDecodable<T>.Error())
    }

}
