//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LossyCollections.swift
//
//  Created by Nacho Soto on 4/26/22.

import Foundation

// Inspired by https://github.com/marksands/BetterCodable/blob/master/Sources/BetterCodable/

// MARK: - LossyArray

/// A property wrapper that allows decoding `Array`s and ignore elements that fail to decode.
/// For example, this will ignore any elements that aren't numbers, instead of failing to decode altogether.
/// ```
/// struct Data: Decodable {
///     @LossyArray var list: [Int]
/// }
/// ```
/// This does require that the value is an `Array`,
/// but this wrapper can be composed with `@DefaultDecodable.EmptyArray`
/// to make it produce an empty array in case of any other type error.
/// ```
/// struct Data: Decodable {
///      @DefaultDecodable.EmptyArray @LossyArray var list: [Int]
/// }
/// ```
@propertyWrapper
struct LossyArray<Value> {

    var wrappedValue: [Value]

    init(wrappedValue: [Value]) { self.wrappedValue = wrappedValue }

}

extension LossyArray: Decodable where Value: Decodable {

    private struct AnyDecodableValue: Decodable {}

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var elements: [Value] = []
        while !container.isAtEnd {
            do {
                elements.append(try container.decode(Value.self))
            } catch {
                do {
                    // Attempt to decode anything to skip this element
                    _ = try container.decode(AnyDecodableValue.self)
                } catch {
                    ErrorUtils.logDecodingError(error)
                }
            }
        }

        self.wrappedValue = elements
    }

}

extension LossyArray: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

}

extension LossyArray: Equatable where Value: Equatable { }
extension LossyArray: Hashable where Value: Hashable { }

extension LossyArray: ExpressibleByArrayLiteral {

    init(arrayLiteral elements: Value...) {
        self.wrappedValue = elements
    }

}

// MARK: - LossyDictionary

/// A property wrapper that allows decoding `Dictionary`s and ignore elements that fail to decode.
/// For example, this will ignore any elements that aren't numbers, instead of failing to decode altogether.
/// ```
/// struct Data: Decodable {
///     @LossyDictionary var map: [String: Int]
/// }
/// ```
/// This does require that the value is a `Dictionary`,
/// but this wrapper can be composed with `@DefaultDecodable.EmptyDictionary`
/// to make it produce an empty dictionary in case of any other type error.
/// ```
/// struct Data: Decodable {
///      @DefaultDecodable.EmptyDictionary @LossyDictionary var map: [String: Int]
/// }
/// ```
/// - Note: if the values of the dictionary are an array, consider using `LossyArrayDictionary`.
@propertyWrapper
struct LossyDictionary<Value: Decodable> {

    var wrappedValue: [String: Value]

    init(wrappedValue: [String: Value]) {
        self.wrappedValue = wrappedValue
    }

}

/// A property wrapper that allows decoding `Dictionary`s of `Array`s and ignore elements that fail to decode.
/// This is a composition of `LossyArray` and `LossyDictionary`, that due to limitations of property wrappers,
/// it necessitates its own type.
@propertyWrapper
struct LossyArrayDictionary<Value: Decodable> {

    var wrappedValue: [String: [Value]]

    init(wrappedValue: [String: [Value]]) {
        self.wrappedValue = wrappedValue
    }

}

// MARK: - LossyDictionary implementation

private struct DictionaryCodingKey: CodingKey {

    let stringValue: String
    var intValue: Int? { return Int(self.stringValue) }

    init?(intValue: Int) { self.stringValue = String(intValue) }
    init?(stringValue: String) { self.stringValue = stringValue }

}

extension LossyDictionary: Decodable {

    private struct AnyDecodableValue: Decodable {}

    init(from decoder: Decoder) throws {
        var elements: [String: Value] = [:]

        let container = try decoder.container(keyedBy: DictionaryCodingKey.self)
        let keys = try Self.extractKeys(from: decoder, container: container)

        for (key, stringKey) in keys {
            do {
                elements[stringKey] = try container.decode(Value.self, forKey: key)
            } catch {
                ErrorUtils.logDecodingError(error)
            }
        }

        self.wrappedValue = elements
    }

    fileprivate static func extractKeys(
        from decoder: Decoder,
        container: KeyedDecodingContainer<DictionaryCodingKey>
    ) throws -> AnySequence<(DictionaryCodingKey, String)> {
        // Decode a dictionary ignoring the values to decode the original keys
        // without using the `JSONDecoder.KeyDecodingStrategy`.
        let keys = try decoder.singleValueContainer().decode([String: AnyDecodableValue].self).keys

        return AnySequence(
            zip(
                container.allKeys.sorted(by: { $0.stringValue < $1.stringValue }),
                keys.sorted()
            )
        )
    }

}

extension LossyArrayDictionary: Decodable {

    init(from decoder: Decoder) throws {
        var elements: [String: [Value]] = [:]

        let container = try decoder.container(keyedBy: DictionaryCodingKey.self)
        let keys = try LossyDictionary<Value>.extractKeys(from: decoder, container: container)

        for (key, stringKey) in keys {
            do {
                let arrayDecoder = try container.superDecoder(forKey: key)
                elements[stringKey] = try LossyArray(from: arrayDecoder).wrappedValue
            } catch {
                ErrorUtils.logDecodingError(error)
            }
        }

        self.wrappedValue = elements
    }

}

extension LossyDictionary: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

}

extension LossyDictionary: Equatable where Value: Equatable { }
extension LossyDictionary: Hashable where Value: Hashable { }

extension LossyDictionary: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (String, Value)...) {
        self.wrappedValue = Dictionary(uniqueKeysWithValues: elements)
    }

}

extension LossyArrayDictionary: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

}

extension LossyArrayDictionary: Equatable where Value: Equatable { }
extension LossyArrayDictionary: Hashable where Value: Hashable { }

extension LossyArrayDictionary: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (String, [Value])...) {
        self.wrappedValue = Dictionary(uniqueKeysWithValues: elements)
    }

}
