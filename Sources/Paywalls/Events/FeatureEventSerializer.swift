//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventSerializer.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum FeatureEventSerializer {

    private struct FailedEncodingEventError: Error {}

    /// Encodes a `FeatureEvent` in a format suitable to be stored by `FeatureEventStore`.
    static func encode<T: FeatureEvent>(_ event: StoredFeatureEvent<T>) throws -> String {
        let data = try JSONEncoder.default.encode(value: event)

        return try String(data: data, encoding: .utf8)
            .orThrow(FailedEncodingEventError())
    }

    /// Decodes a `FeatureEvent`.
    static func decode<T: FeatureEvent>(_ event: String) throws -> StoredFeatureEvent<T> {
        return try JSONDecoder.default.decode(jsonData: event.asData)
    }

}
