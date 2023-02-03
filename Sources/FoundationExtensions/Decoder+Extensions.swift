//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Decoder+Extensions.swift
//
//  Created by Joshua Liebowitz on 10/25/21.

import Foundation

// swiftlint:disable nesting

extension Decoder {

    func valueNotFoundError(expectedType: Any.Type, message: String) -> CodableError {
        let context = DecodingError.Context(codingPath: codingPath,
                                            debugDescription: message,
                                            underlyingError: nil)
        return CodableError.valueNotFound(value: expectedType, context: context)
    }

}

// MARK: - DefaultValueProvider

/// A type that can provide a default value.
protocol DefaultValueProvider {

    associatedtype Value

    static var defaultValue: Value { get }

}

// MARK: - DefaultValue

/// A property wrapper for providing a default value to properties that conform to `DefaultValueProvider`.
/// This is similar to `@IgnoreDecodeErrors` but it will not ignore decoding errors.
/// - Example:
/// ```
/// struct Data {
///     @DefaultValue<E> var e: E
/// }
/// ```
@propertyWrapper
struct DefaultValue<Source: DefaultValueProvider> {

    typealias Value = Source.Value

    var wrappedValue = Source.defaultValue

}

extension DefaultValue: Equatable where Value: Equatable {}
extension DefaultValue: Hashable where Value: Hashable {}

extension DefaultValue: Decodable where Value: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(Value.self)
    }

}

extension DefaultValue: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension Optional: DefaultValueProvider {

    static var defaultValue: Wrapped? { return .none }

}

// MARK: - IgnoreEncodable

/// A property wrapper that allows not encoding a value.
/// - Example:
/// ```
/// struct Data {
///     @IgnoreEncodable var data: String // this value won't be encoded
/// }
/// ```
@propertyWrapper
struct IgnoreEncodable<Value> {

    var wrappedValue: Value

}

extension IgnoreEncodable: Decodable where Value: Decodable {

    init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.singleValueContainer().decode(Value.self)
    }

}

extension IgnoreEncodable: Encodable {

    func encode(to encoder: Encoder) throws {}

}

extension IgnoreEncodable: Equatable where Value: Equatable {}
extension IgnoreEncodable: Hashable where Value: Hashable {}

extension KeyedEncodingContainer {

    mutating func encode<T>(_ value: IgnoreEncodable<T>, forKey key: K) throws {}

}

// MARK: - IgnoreDecodeErrors

/// A property wrapper that allows ignoring decoding errors for `DefaultValueProvider` properties (like `Optional`)
/// This is similar to `@DefaultValue` but it will also decode as `Source.defaultValue` if there are any errors
/// - Example:
/// ```
/// struct Data {
///     @IgnoreDecodingErrors<URL?> var url: URL? // becomes `nil` if url is invalid
/// }
/// ```
@propertyWrapper
struct IgnoreDecodeErrors<Source: DefaultValueProvider> {

    typealias Value = Source.Value

    var wrappedValue: Value = Source.defaultValue

}

extension IgnoreDecodeErrors: Equatable where Value: Equatable {}
extension IgnoreDecodeErrors: Hashable where Value: Hashable {}

extension IgnoreDecodeErrors: Decodable where Value: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(Value.self)
    }

}

extension IgnoreDecodeErrors: Encodable where Value: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

}

extension KeyedDecodingContainer {

    func decode<T>(
        _ type: IgnoreDecodeErrors<T>.Type,
        forKey key: Key
    ) -> IgnoreDecodeErrors<T> where T.Value: Decodable {
        do {
            return try self.decodeIfPresent(type, forKey: key) ?? .init()
        } catch {
            return .init()
        }
    }

}

// MARK: - DefaultDecodable

// Inspired by https://swiftbysundell.com/tips/default-decoding-values/

extension KeyedDecodingContainer {

    func decode<T>(_ type: DefaultValue<T>.Type, forKey key: Key) throws -> DefaultValue<T> where T.Value: Decodable {
        return try self.decodeIfPresent(type, forKey: key) ?? .init()
    }

}

/// Empty namespace for default decodable wrappers.
enum DefaultDecodable {

    typealias List = Decodable & ExpressibleByArrayLiteral
    typealias Map = Decodable & ExpressibleByDictionaryLiteral

    enum Sources {

        enum True: DefaultValueProvider {
            static var defaultValue: Bool { true }
        }

        enum False: DefaultValueProvider {
            static var defaultValue: Bool { false }
        }

        enum EmptyString: DefaultValueProvider {
            static var defaultValue: String { "" }
        }

        enum EmptyArray<T: List>: DefaultValueProvider {
            static var defaultValue: T { [] }
        }

        enum EmptyDictionary<T: Map>: DefaultValueProvider {
            static var defaultValue: T { [:] }
        }

    }

}

/**
 * Property wrappers to allow providing default values to properties in `Decodable` types.
 * Example usage:
 * ```
 * struct Data {
 *   @DefaultDecodable.True var bool1: Bool
 *   @DefaultDecodable.False var bool2: Bool
 *   @DefaultDecodable.EmptyString var identifier: String
 *   @DefaultDecodable.EmptyArray var values: [String]
 *   @DefaultDecodable.EmptyDictionary var dictionary: [String: Int]
 * }
 * ```
 */
extension DefaultDecodable {

    typealias True = DefaultValue<Sources.True>
    typealias False = DefaultValue<Sources.False>
    typealias EmptyString = DefaultValue<Sources.EmptyString>
    typealias EmptyArray<T: List> = DefaultValue<Sources.EmptyArray<T>>
    typealias EmptyDictionary<T: Map> = DefaultValue<Sources.EmptyDictionary<T>>

}
