//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EnsureNonEmptyCollectionDecodable.swift
//
//  Created by Nacho Soto on 7/17/23.

import Foundation

/// A property wrapper that ensures decoded collections aren't empty.
/// - Example:
/// ```
/// struct Data {
///     @EnsureNonEmptyCollectionDecodable var values: [String] // fails to decode if array is empty
///     @EnsureNonEmptyCollectionDecodable var dictionary: [String: String] // fails to decode if dictionary is empty
/// }
/// ```
@propertyWrapper
struct EnsureNonEmptyCollectionDecodable<Value: Collection> where Value: Codable {

    struct Error: LocalizedError {

        var path: String?

        init(codingPath: String? = nil) {
            self.path = codingPath
        }

        /// Error message explaining that the collection cannot be empty
        public var localizedDescription: String? {
            "Collection cannot be empty"
        }

        /// Error message that includes the path that contains the empty collection
        public var failureReason: String? {
            "A collection at \(path ?? "unknown") was unexpectedly empty."
        }

    }

    var wrappedValue: Value

}

extension EnsureNonEmptyCollectionDecodable: Equatable where Value: Equatable {}
extension EnsureNonEmptyCollectionDecodable: Hashable where Value: Hashable {}

extension EnsureNonEmptyCollectionDecodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode(Value.self)

        if array.isEmpty {
            throw Error(codingPath: "\(decoder.codingPath)")
        } else {
            self.wrappedValue = array
        }
    }

}

extension EnsureNonEmptyCollectionDecodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension KeyedDecodingContainer {

    func decode<T>(
        _ type: EnsureNonEmptyCollectionDecodable<T>.Type,
        forKey key: Key
    ) throws -> EnsureNonEmptyCollectionDecodable<T> {
        return try self.decodeIfPresent(type, forKey: key)
            .orThrow(EnsureNonEmptyCollectionDecodable<T>.Error(codingPath: "\(self.codingPath)"))
    }

}
