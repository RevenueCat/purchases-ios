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

    var description: String {
        switch self {
        case .unexpectedValue(let type):
            return Strings.codable.unexpectedValueError(type: type).description
        case .valueNotFound(let value, let context):
            return Strings.codable.valueNotFoundError(value: value, context: context).description
        }
    }
}

extension JSONDecoder {

    /// Decodes a top-level value of the given type from the given Dictionary.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode. The default is `T.self`.
    ///   - dictionary: The dictionary to decode from.
    ///   - keyDecodingStrategy: The strategy to use for automatically changing the
    ///   value of keys before decoding. The default is `useDefaultKeys`.
    ///   - dateDecodingStrategy: The strategy to use for decoding `Date` values. The default is `deferredToDate`.
    ///   - dataDecodingStrategy: The strategy to use for decoding `Data` values. The default is `deferredToData`.
    /// - Returns: A value of the requested type.
    /// - throws: An error if it throws an error during initializating the data.
    /// - throws: An error if any value throws an error during decoding.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        dictionary: [String: Any],
        keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: DataDecodingStrategy = .deferredToData
    ) throws -> T? {

        self.keyDecodingStrategy = keyDecodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy

        if JSONSerialization.isValidJSONObject(dictionary) {
            let maybeJsonData = try JSONSerialization.data(withJSONObject: dictionary)
            do {
                return try decode(type, from: maybeJsonData)
            } catch {
                ErrorUtils.logDecodingError(error)
                return nil
            }
        } else {
            Logger.error(Strings.codable.invalid_json_error(jsonData: dictionary))
            return nil
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
            ErrorUtils.logDecodingError(error)
            return defaultValue
        }
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
            Logger.error(Strings.codable.keyNotFoundError(key: key, context: context))
        case .valueNotFound(let value, let context):
            Logger.error(Strings.codable.valueNotFoundError(value: value, context: context))
        case .typeMismatch(let type, let context):
            Logger.error(Strings.codable.typeMismatch(type: type, context: context))
        default:
            Logger.error("Unhandled DecodingError: \(decodingError)\n\(Strings.codable.decoding_error(decodingError))")
        }
     }

}
