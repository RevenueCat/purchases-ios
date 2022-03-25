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

    // swiftlint:disable:next missing_docs
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let storeString = try? container.decode(String.self) else {
            throw decoder.throwValueNotFoundError(expectedType: Store.self, message: "Unable to extract a storeString")
        }

        guard let type = Self.mapping[storeString] else {
            throw CodableError.unexpectedValue(Store.self)
        }

        self = type
    }

    private static let mapping: [String: Self] = Self.allCases
        .reduce(into: [:]) { result, store in
            if let name = store.name { result[name] = store }
        }

}

private extension Store {

    var name: String? {
        switch self {
        case .appStore: return "app_store"
        case .macAppStore: return "mac_app_store"
        case .playStore: return "play_store"
        case .stripe: return "stripe"
        case .promotional: return "promotional"
        case .unknownStore: return nil
        }
    }

}
