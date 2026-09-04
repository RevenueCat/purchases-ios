//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyDecodable+DimensionValue.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

import Foundation

extension AnyDecodable {

    var dimensionValue: DimensionValue? {
        switch self {
        case let .string(value): return .string(value)
        case let .int(value): return .int(Int64(value))
        case let .double(value): return .double(value)
        case let .bool(value): return .bool(value)
        case let .object(value):
            return .object(value.compactMapValues(\AnyDecodable.dimensionValue))
        case let .array(value):
            let objects = value.compactMap { element -> [String: DimensionValue]? in
                guard case let .object(object) = element else { return nil }
                return object.compactMapValues(\AnyDecodable.dimensionValue)
            }
            return objects.count == value.count ? .objectList(objects) : nil
        case .null: return .null
        }
    }

}
