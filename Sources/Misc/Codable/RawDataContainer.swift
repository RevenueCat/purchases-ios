//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RawDataContainer.swift
//
//  Created by Nacho Soto on 11/16/21.

/// A type which exposes its underlying content for debugging purposes or for getting access
/// to future data while using an older version of the SDK.
public protocol RawDataContainer {

    /// The type of the ``RawDataContainer/rawData`` for this type.
    associatedtype Content

    /// The underlying content for debugging purposes or for getting access
    /// to future data while using an older version of the SDK.
    var rawData: Content { get }

}

extension Decoder {

    /// Decodes the entire content of this `Decoder` into `[String: Any]` to be used for a `RawDataContainer` type.
    func decodeRawData() -> [String: Any] {
        do {
            let value = try self.singleValueContainer()
                .decode(AnyDecodable.self)
                .asAny

            guard let dictionary = value as? [String: Any] else {
                Logger.warn(Strings.codable.unexpectedValueError(type: type(of: value), value: value))
                return [:]
            }

            return dictionary
        } catch {
            Logger.warn(Strings.codable.decoding_error(error, AnyDecodable.self))
            return [:]
        }
    }

}
