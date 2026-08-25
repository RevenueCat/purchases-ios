//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DimensionValue+JSON.swift
//
//  Created by Facundo Menzella on 25/8/26.
//

import Foundation

extension DimensionValue {

    /// Carries a JSON object the SDK does not interpret into the shape the resolver hands the engine.
    ///
    /// Names the SDK has never heard of come through unchanged, which is what lets the backend
    /// describe a customer in ways this version was never taught. A value JSON Logic has no reading
    /// for is left out rather than guessed at.
    static func dimensions(from json: [String: Any]) -> [String: DimensionValue] {
        return json.reduce(into: [:]) { dimensions, entry in
            dimensions[entry.key] = DimensionValue(json: entry.value)
        }
    }

    // `NSNumber` is how `JSONSerialization` hands back every number and every boolean, so the
    // distinction between them survives only through its object type.
    init?(json: Any) {
        switch json {
        case let value as String:
            self = .string(value)

        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else if CFNumberIsFloatType(value) {
                self = .double(value.doubleValue)
            } else {
                self = .int(value.int64Value)
            }

        case let value as [String: Any]:
            self = .object(DimensionValue.dimensions(from: value))

        case let value as [Any]:
            // A collection is only readable by an iteration operator, which walks records. Anything
            // else in it has no reading, so a mixed or scalar array is left out entirely.
            let records = value.compactMap { $0 as? [String: Any] }
            guard records.count == value.count else { return nil }
            self = .objectList(records.map(DimensionValue.dimensions(from:)))

        default:
            // `null`, and anything `JSONSerialization` produces that JSON Logic cannot compare.
            return nil
        }
    }

}
