//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Store+Extensions.swift
//
//  Created by Juanpe Catalán on 26/8/21.

import Foundation

extension Store: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let storeString = try? container.decode(String.self) else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Unable to extract a storeString",
                                                underlyingError: nil)
            throw CodableError.valueNotFound(value: Store.self, context: context)
        }

        switch storeString {
        case "app_store":
            self = .appStore
        case "mac_app_store":
            self = .macAppStore
        case "play_store":
            self = .playStore
        case "stripe":
            self = .stripe
        case "promotional":
            self = .promotional
        default:
            throw CodableError.unexpectedValue(Store.self)
        }
    }

}
