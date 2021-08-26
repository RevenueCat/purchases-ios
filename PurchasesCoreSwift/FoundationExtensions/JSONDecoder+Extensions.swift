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

extension JSONDecoder {

    /// Decodes a top-level value of the given type from the given Dictionary.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode. The default is `T.self`.
    ///   - dictionary: The dictionary to decode from.
    ///   - keyDecodingStrategy: The strategy to use for automatically changing the value of keys before decoding. The default is `useDefaultKeys`.
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
    ) throws -> T {

        self.keyDecodingStrategy = keyDecodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy

        let maybeJsonData = try JSONSerialization.data(withJSONObject: dictionary)

        return try decode(type, from: maybeJsonData)
    }

}
