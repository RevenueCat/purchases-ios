//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesResponse.swift
//
//  Created by Will Taylor on 6/10/25.

import Foundation

struct VirtualCurrenciesResponse {

    let virtualCurrencies: [String: VirtualCurrencyResponse]

    struct VirtualCurrencyResponse {
        let balance: Int
        let name: String
        let code: String
        let description: String?
    }
}

extension VirtualCurrenciesResponse.VirtualCurrencyResponse: Codable, Equatable {}
extension VirtualCurrenciesResponse: Codable, Equatable {}

extension VirtualCurrenciesResponse: HTTPResponseBody {
    static func create(with data: Data) throws -> Self {
        return try JSONDecoder.default.decode(Self.self, from: data)
    }
}
