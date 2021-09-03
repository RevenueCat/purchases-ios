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

    static func unexpectedValueError(for type: Any.Type) -> String {
        "Found unexpected value for type: \(type)"
    }
    static func valueNotFoundError(for type: Any.Type) -> String {
        "No value found for type: \(type)"
    }

    case invalid_json_error(jsonData: [String: Any])

    case decoding_error(errorMessage: String)

}

extension CodableStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .invalid_json_error(let jsonData):
            return "The given json data was not valid: \n\(jsonData)"

        case .decoding_error(let errorMessage):
            return "Couldn't decode data from json. Error: \n\(errorMessage)"

        }
    }
}
