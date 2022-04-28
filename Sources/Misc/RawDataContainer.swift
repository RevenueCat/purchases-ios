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

    /// The type of the `underlyingData` for this type.
    associatedtype Content: Encodable

    /// The underlying content for debugging purposes or for getting access
    /// to future data while using an older version of the SDK.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    var underlyingData: Content { get }

}

/// Default implementation that encodes the `underlyingData` for public use.
extension RawDataContainer {

    /// The underlying data for this type, for debugging purposes or for getting access
    /// to future data while using an older version of the SDK.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    public var rawData: [String: Any] {
        do {
            return try self.underlyingData.asDictionary()
        } catch {
            Logger.warn(Strings.codable.encoding_error(error))
            return [:]
        }
    }

}
