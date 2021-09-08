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
    case valueNotFoundError(type: Any.Type)
    case invalid_json_error(jsonData: [String: Any])
    case decoding_error(errorMessage: String)

}

extension CodableStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .unexpectedValueError(let type):
            return "Found unexpected value for type: \(type)"

        case .valueNotFoundError(let type):
            return "No value found for type: \(type)"

        case .invalid_json_error(let jsonData):
            return "The given json data was not valid: \n\(jsonData)"

        case .decoding_error(let errorMessage):
            return "Couldn't decode data from json. Error: \n\(errorMessage)"

        }
    }

}
