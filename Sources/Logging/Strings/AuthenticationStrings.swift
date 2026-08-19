//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AuthenticationStrings.swift
//
//  Created by Dave DeLong on 8/19/26.

import Foundation

// swiftlint:disable identifier_name
enum AuthenticationStrings {

    case unknownItem(_ key: String)
    case failedModification(_ key: String, _ error: any Error)
}


extension AuthenticationStrings: LogMessage {

    var description: String {
        switch self {
        case .unknownItem(let key):
            return "Unknown secure item: \(key)"
        case .failedModification(let key, let error):
            return "Failed to modify item \(key): \(error)"
        }
    }

    var category: String { "authentication" }
}
