//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyCodable.swift
//
//  Created by Nacho Soto on 3/2/22.

import Foundation

// Inspired by https://github.com/Flight-School/AnyCodable

/// Type-erased `Any` that conforms to `Encodable` and `Decodable`
enum AnyCodable {

    case string(String)
    case int(Int)
    case uint64(UInt64)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case url(URL)
    case object([String: AnyCodable])
    case array([AnyCodable])
    case null

    // swiftlint:disable cyclomatic_complexity

    /// Creates an `AnyCodable` from any value
    /// - Throws: `EncodingError` if the type cannot be encoded.
    init(_ value: Any?) throws {
        switch value {
        case is NSNull, is Void, nil:
            self = .null
        case let bool as Bool:
            self = .bool(bool)
        case let int as Int:
            self = .int(int)
        case let uint as UInt:
            self = .uint64(UInt64(uint))
        case let float as Float:
            self = .double(Double(float))
        case let double as Double:
            self = .double(double)
        case let string as String:
            self = .string(string)
        case let date as Date:
            self = .date(date)
        case let url as URL:
            self = .url(url)
        case let array as [Any]:
            self = .array(try array.map(AnyCodable.init))
        case let dictionary as [String: Any?]:
            self = .object(try dictionary.mapValues(AnyCodable.init))
        default:
            throw EncodingError.invalidValue(
                value as Any,
                .init(
                    codingPath: .init(),
                    debugDescription: "Value cannot be encoded"
                )
            )
        }
    }

    // swiftlint:enable cyclomatic_complexity

}

extension AnyCodable {

    var asAny: Any {
        switch self {
        case let .string(value): return value
        case let .int(value): return value
        case let .uint64(value): return value
        case let .double(value): return value
        case let .bool(value): return value
        case let .date(date): return date
        case let .url(url): return url
        case let .object(value): return value.mapValues { $0.asAny }
        case let .array(value): return value.map { $0.asAny }
        case .null: return NSNull()
        }
    }

}

// swiftlint:disable cyclomatic_complexity

// MARK: - Encodable

extension AnyCodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(string): try container.encode(string)
        case let .int(int): try container.encode(int)
        case let .uint64(int): try container.encode(int)
        case let .double(double): try container.encode(double)
        case let .bool(bool): try container.encode(bool)
        case let .date(date): try container.encode(date)
        case let .url(url): try container.encode(url)
        case let .object(dictionary): try container.encode(dictionary)
        case let .array(array): try container.encode(array)
        case .null: try container.encodeNil()
        }
    }

}

// MARK: - Decodable

extension AnyCodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let int = try? container.decode(UInt64.self) {
            self = .uint64(int)
        } else if let uint = try? container.decode(UInt.self) {
            self = .int(Int(uint))
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let float = try? container.decode(Float.self) {
            self = .double(Double(float))
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let url = try? container.decode(URL.self) {
            self = .url(url)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self = .object(dictionary)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

}

// MARK: - Equatable

extension AnyCodable: Equatable {}

// MARK: - Sendable

extension AnyCodable: Sendable {}

// swiftlint:enable cyclomatic_complexity

// MARK: - Expressible by Literal

extension AnyCodable: ExpressibleByNilLiteral {

    init(nilLiteral: ()) {
        self = .null
    }

}

extension AnyCodable: ExpressibleByStringLiteral {

    init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }

}

extension AnyCodable: ExpressibleByIntegerLiteral {

    init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }

}

extension AnyCodable: ExpressibleByBooleanLiteral {

    init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }

}

extension AnyCodable: ExpressibleByFloatLiteral {

    init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }

}

extension AnyCodable: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (String, AnyCodable)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }

}

extension AnyCodable: ExpressibleByArrayLiteral {

    init(arrayLiteral elements: AnyCodable...) {
        self = .array(elements)
    }

}
