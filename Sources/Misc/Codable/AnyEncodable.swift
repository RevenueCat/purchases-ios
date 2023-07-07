//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyEncodable.swift
//
//  Created by Nacho Soto on 3/2/22.

import Foundation

// Inspired by https://github.com/Flight-School/AnyCodable

struct AnyEncodable {

    let value: Any

    init<T>(_ value: T?) { self.value = value ?? () }

}

// swiftlint:disable cyclomatic_complexity

extension AnyEncodable: Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt:
            try container.encode(uint)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any?]:
            try container.encode(array.map(AnyEncodable.init))
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues(AnyEncodable.init))
        case let encodable as Encodable:
            try encodable.encode(to: encoder)

        default:
            throw EncodingError.invalidValue(
                self.value,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "AnyEncodable value cannot be encoded"
                )
            )
        }
    }

}

/// `AnyEncodable` can also be decoded
extension AnyEncodable: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let float = try? container.decode(Float.self) {
            self.value = float
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let date = try? container.decode(Date.self) {
            self.value = date
        } else if let url = try? container.decode(URL.self) {
            self.value = url
        } else if let array = try? container.decode([AnyEncodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyEncodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyEncodable value cannot be decoded"
            )
        }
    }

}

// swiftlint:enable cyclomatic_complexity
