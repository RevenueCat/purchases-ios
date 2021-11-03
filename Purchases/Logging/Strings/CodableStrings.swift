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

    case unexpectedValueError(type: Any.Type)
    case valueNotFoundError(value: Any.Type, context: DecodingError.Context)
    case keyNotFoundError(key: CodingKey, context: DecodingError.Context)
    case invalid_json_error(jsonData: [String: Any])
    case decoding_error(_ error: Error)
    case corrupted_data_error(context: DecodingError.Context)
    case typeMismatch(type: Any, context: DecodingError.Context)

}

extension CodableStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .unexpectedValueError(let type):
            return "Found unexpected value for type: \(type)"
        case .valueNotFoundError(let value, let context):
            let description = context.debugDescription
            return "No value found for: \(value), codingPath: \(context.codingPath), description:\n\(description)"
        case .keyNotFoundError(let key, let context):
            let description = context.debugDescription
            return "Key '\(key)' not found, codingPath: \(context.codingPath), description:\n\(description)"
        case .invalid_json_error(let jsonData):
            return "The given json data was not valid: \n\(jsonData)"
        case .decoding_error(let error):
            return "Couldn't decode data from json. Error:\n\(error.localizedDescription))"
        case .corrupted_data_error(let context):
            return "Couldn't decode data from json, it was corrupted: \(context)"
        case .typeMismatch(let type, let context):
            let description = context.debugDescription
            return "Type '\(type)' mismatch, codingPath:\(context.codingPath), description:\n\(description)"
        }
    }

}
