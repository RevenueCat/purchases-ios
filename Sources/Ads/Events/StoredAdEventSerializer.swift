//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoredAdEventSerializer.swift
//
//  Created by RevenueCat on 1/21/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum StoredAdEventSerializer {

    private struct FailedEncodingEventError: Error {}

    /// Encodes a ``StoredAdEvent`` in a format suitable to be stored by `AdEventStore`.
    static func encode(_ event: StoredAdEvent) throws -> String {
        let data = try JSONEncoder.default.encode(value: event)

        return try String(data: data, encoding: .utf8)
            .orThrow(FailedEncodingEventError())
    }

    /// Decodes a ``StoredAdEvent``.
    static func decode(_ event: String) throws -> StoredAdEvent {
        return try JSONDecoder.default.decode(jsonData: event.asData)
    }

}

#endif
