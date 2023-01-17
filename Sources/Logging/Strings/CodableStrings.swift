//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CodableStrings.swift
//
//  Created by Juanpe Catalán on 29/8/21.

import Foundation

// swiftlint:disable identifier_name
enum CodableStrings {

    case unexpectedValueError(type: Any.Type, value: Any)
    case valueNotFoundError(value: Any.Type, context: DecodingError.Context)
    case keyNotFoundError(type: Any.Type, key: CodingKey, context: DecodingError.Context)
    case invalid_json_error(jsonData: [String: Any])
    case encoding_error(_ error: Error)
    case decoding_error(_ error: Error)
    case corrupted_data_error(context: DecodingError.Context)
    case typeMismatch(type: Any, context: DecodingError.Context)

}

extension CodableStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .unexpectedValueError(type, value):
            return "Found unexpected value '\(value)' for type '\(type)'"
        case let .valueNotFoundError(value, context):
            let description = context.debugDescription
            return "No value found for: \(value), codingPath: \(context.codingPath), description:\n\(description)"
        case let .keyNotFoundError(type, key, context):
            let description = context.debugDescription
            return "Error deserializing `\(type)`. " +
            "Key '\(key)' not found, codingPath: \(context.codingPath), description:\n\(description)"
        case let .invalid_json_error(jsonData):
            return "The given json data was not valid: \n\(jsonData)"
        case let .encoding_error(error):
            return "Couldn't encode data into json. Error:\n\(error.localizedDescription)"
        case let .decoding_error(error):
            let underlyingErrorMessage: String
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
                underlyingErrorMessage = "\nUnderlying error: \(underlyingError.debugDescription)"
            } else {
                underlyingErrorMessage = ""
            }

            return "Couldn't decode data from json.\nError: \(error.localizedDescription)." + underlyingErrorMessage
        case let .corrupted_data_error(context):
            return "Couldn't decode data from json, it was corrupted: \(context)"
        case let .typeMismatch(type, context):
            let description = context.debugDescription
            return "Type '\(type)' mismatch, codingPath:\(context.codingPath), description:\n\(description)"
        }
    }

}
