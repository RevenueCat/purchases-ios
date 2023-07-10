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

/// Type erased `Any` that conforms to `Encodable` and `Decodable`
struct AnyCodable {

    let value: Any

    init<T>(_ value: T?) {
        if let codable = value as? AnyCodable {
            self.value = codable.value
        } else {
            if let value = value, !(value is Void) {
                self.value = value
            } else {
                self.value = NSNull()
            }
        }
    }

}

// swiftlint:disable cyclomatic_complexity

// MARK: - Encodable

extension AnyCodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self.value {
        case is NSNull, is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt:
            try container.encode(uint)
        case let double as Double:
            try container.encode(double)
        case let float as Float:
            try container.encode(float)
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any?]:
            try container.encode(array.map(AnyCodable.init))
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues(AnyCodable.init))
        case let encodable as Encodable:
            try encodable.encode(to: encoder)

        default:
            throw EncodingError.invalidValue(
                self.value,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"
                )
            )
        }
    }

}

// MARK: - Decodable

extension AnyCodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let float = try? container.decode(Float.self) {
            self.value = float
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let date = try? container.decode(Date.self) {
            self.value = date
        } else if let url = try? container.decode(URL.self) {
            self.value = url
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

}

// swiftlint:enable cyclomatic_complexity

// MARK: -

extension AnyCodable: Equatable {

    // swiftlint:disable:next cyclomatic_complexity
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value as Any?, rhs.value as Any?) {
        case is (Void, Void), is (NSNull, NSNull), is (Void, NSNull), is (NSNull, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: Any]):
            return lhs == rhs.mapValues(AnyCodable.init)
        case let (lhs as [String: Any], rhs as [String: AnyCodable]):
            return lhs.mapValues(AnyCodable.init) == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [Any]):
            return lhs == rhs.map(AnyCodable.init)
        case let (lhs as [Any], rhs as [AnyCodable]):
            return lhs.map(AnyCodable.init) == rhs
        default:
            return false
        }
    }
}

// MARK: - Expressible by Literal

extension AnyCodable: ExpressibleByNilLiteral {

    init(nilLiteral: ()) {
        self.init(nilLiteral)
    }

}

extension AnyCodable: ExpressibleByStringLiteral {

    init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

}

extension AnyCodable: ExpressibleByIntegerLiteral {

    init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }

}

extension AnyCodable: ExpressibleByBooleanLiteral {

    init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }

}

extension AnyCodable: ExpressibleByFloatLiteral {

    init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }

}

extension AnyCodable: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (AnyHashable, AnyCodable)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }

}

extension AnyCodable: ExpressibleByArrayLiteral {

    init(arrayLiteral elements: AnyCodable...) {
        self.init(elements)
    }

}
