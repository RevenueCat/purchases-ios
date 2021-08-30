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
    static let invalid_json_error: String = "The given data was not valid JSON\n%@"
    static let decoding_error = "Couldn't decode data from json\n%@"
}
