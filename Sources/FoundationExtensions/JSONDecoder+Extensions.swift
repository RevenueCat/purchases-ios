//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  JSONDecoder+Extensions.swift
//
//  Created by Juanpe Catalán on 25/8/21.

import Foundation

enum CodableError: Error, CustomStringConvertible {

    case unexpectedValue(Any.Type)
    case valueNotFound(value: Any.Type, context: DecodingError.Context)
    case invalidJSONObject(value: [String: Any])

    var description: String {
        switch self {
        case let .unexpectedValue(type):
            return Strings.codable.unexpectedValueError(type: type).description
        case let .valueNotFound(value, context):
            return Strings.codable.valueNotFoundError(value: value, context: context).description
        case let .invalidJSONObject(value):
            return Strings.codable.invalid_json_error(jsonData: value).description
        }
    }
}

extension JSONDecoder {

    /// Decodes a top-level value of the given type from the given Data containing a JSON representation of `type`.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode. The default is `T.self`.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - throws: `CodableError` or `DecodableError` if the data is invalid or can't be deserialized.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        jsonData: Data,
        logErrors: Bool = true
    ) throws -> T {
        do {
            return try self.decode(type, from: jsonData)
        } catch {
            if logErrors {
                ErrorUtils.logDecodingError(error)
            }
            throw error
        }
    }

    /// Decodes a top-level value of the given type from the given Dictionary.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode. The default is `T.self`.
    ///   - dictionary: The dictionary to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: `CodableError` or `DecodableError` if the data is invalid or can't be deserialized.
    /// - Note: this method logs the error before throwing, so it's "safe" to use with `try?`
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        dictionary: [String: Any],
        logErrors: Bool = true
    ) throws -> T {
        if JSONSerialization.isValidJSONObject(dictionary) {
            return try self.decode(type,
                                   jsonData: try JSONSerialization.data(withJSONObject: dictionary),
                                   logErrors: logErrors)
        } else {
            throw CodableError.invalidJSONObject(value: dictionary)
        }
    }

}

extension KeyedDecodingContainer {

    /// Decodes a value of the given type for the given key.
    /// - Parameters:
    ///   - type: The type of value to decode.
    ///   - key: The key that the decoded value is associated with.
    ///   - defaultValue: The default value returned if decoding fails.
    /// - Returns: A value of the requested type, or the given default value
    /// if decoding fails.
    func decode<T: Decodable>(_ type: T.Type, forKey key: Self.Key, defaultValue: T) -> T {
        do {
            return try decode(type, forKey: key)
        } catch {
            return defaultValue
        }
    }

}

extension JSONSerialization {

    static func dictionary(withData data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)

        guard let object = object as? [String: Any] else {
            throw CodableError.unexpectedValue(type(of: object))
        }

        return object
    }

}

// MARK: Decoding Error handling
private extension ErrorUtils {

    static func logDecodingError(_ error: Error) {
        guard let decodingError = error as? DecodingError else {
            Logger.error(Strings.codable.decoding_error(error))
            return
        }

        switch decodingError {
        case .dataCorrupted(let context):
            Logger.error(Strings.codable.corrupted_data_error(context: context))
        case .keyNotFound(let key, let context):
            // This is expected to happen occasionally, the backend doesn't always populate all key/values.
            Logger.debug(Strings.codable.keyNotFoundError(key: key, context: context))
        case .valueNotFound(let value, let context):
            Logger.debug(Strings.codable.valueNotFoundError(value: value, context: context))
        case .typeMismatch(let type, let context):
            Logger.error(Strings.codable.typeMismatch(type: type, context: context))
        @unknown default:
            Logger.error("Unhandled DecodingError: \(decodingError)\n\(Strings.codable.decoding_error(decodingError))")
        }
     }

}

extension Encodable {

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let result = try JSONSerialization.jsonObject(with: data, options: [])

        guard let result = result as? [String: Any] else {
            throw CodableError.unexpectedValue(type(of: result))
        }

        return result
    }

}

extension JSONEncoder {

    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

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
