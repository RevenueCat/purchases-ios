//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Codable+Extensions.swift
//
//  Created by Nacho Soto on 11/29/22.

import Foundation

extension Encodable {

    /// - Throws: if encoding failed
    /// - Returns: `nil` if the encoded `Data` can't be serialized into a `String`.
    var prettyPrintedJSON: String? {
        get throws {
            return String(data: try self.prettyPrintedData, encoding: .utf8)
        }
    }

    var prettyPrintedData: Data {
        get throws {
            return try JSONEncoder.prettyPrinted.encode(self)
        }
    }

}

extension JSONEncoder {

    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        return encoder
    }()

    static let prettyPrinted: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        return encoder
    }()

}

extension JSONDecoder {

    static let `default`: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return decoder
    }()

}
