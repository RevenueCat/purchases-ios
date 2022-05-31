//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyDecodable.swift
//
//  Created by Nacho Soto on 5/11/22.

import Foundation

/// Type erased `Any` that conforms to `Decodable`
enum AnyDecodable {

    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: AnyDecodable])
    case array([AnyDecodable])
    case null

}

extension AnyDecodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: AnyDecodable].self) {
            self = .object(value)
        } else if let value = try? container.decode([AnyDecodable].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                AnyDecodable.self,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "Unexpected type at \(container.codingPath.description)"
                )
            )
        }
    }

}

extension AnyDecodable {

    var asAny: Any {
        switch self {
        case let .string(value): return value
        case let .int(value): return value
        case let .double(value): return value
        case let .bool(value): return value
        case let .object(value): return value.mapValues { $0.asAny }
        case let .array(value): return value.map { $0.asAny }
        case .null: return NSNull()
        }
    }

}

extension AnyDecodable: Encodable {

    func encode(to encoder: Encoder) throws {
        try AnyEncodable(self.asAny).encode(to: encoder)
    }

}

extension AnyDecodable: Hashable {}

// MARK: - Expressible by Literal

extension AnyDecodable: ExpressibleByNilLiteral {

    init(nilLiteral: ()) {
        self = .null
    }

}

extension AnyDecodable: ExpressibleByStringLiteral {

    init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }

}

extension AnyDecodable: ExpressibleByIntegerLiteral {

    init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }

}

extension AnyDecodable: ExpressibleByBooleanLiteral {

    init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }

}

extension AnyDecodable: ExpressibleByFloatLiteral {

    init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }

}

extension AnyDecodable: ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (String, AnyDecodable)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }

}

extension AnyDecodable: ExpressibleByArrayLiteral {

    init(arrayLiteral elements: AnyDecodable...) {
        self = .array(elements)
    }

}
