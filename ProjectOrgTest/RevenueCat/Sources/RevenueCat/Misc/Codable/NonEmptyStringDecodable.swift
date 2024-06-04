//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NonEmptyStringDecodable.swift
//
//  Created by Nacho Soto on 7/14/23.

import Foundation

/// A property wrapper that ensures decoded strings aren't empty
/// - Example:
/// ```
/// struct Data {
///     @NonEmptyStringDecodable var value: String? // becomes `nil` if value is empty or has only whitespaces
/// }
/// ```
@propertyWrapper
struct NonEmptyStringDecodable {

    var wrappedValue: String?

}

extension NonEmptyStringDecodable: Equatable, Hashable {}

extension NonEmptyStringDecodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(String?.self)?.notEmptyOrWhitespaces
    }

}

extension NonEmptyStringDecodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension KeyedDecodingContainer {

    func decode(
        _ type: NonEmptyStringDecodable.Type,
        forKey key: Key
    ) throws -> NonEmptyStringDecodable {
        return try self.decodeIfPresent(type, forKey: key) ?? .init()
    }

}
