//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NSNumber+JSON.swift
//
//  Created by Rick van der Linden.
//

import Foundation

enum JSONNumberKind {

    case boolean
    case integer
    case floatingPoint

}

extension NSNumber {

    /// The JSON primitive represented by this Foundation number.
    ///
    /// Swift casts cannot distinguish `NSNumber(true)` from `NSNumber(1)` because both bridge to Boolean and
    /// numeric Swift types. Core Foundation preserves the original storage type.
    var jsonNumberKind: JSONNumberKind {
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return .boolean
        }

        switch CFNumberGetType(self as CFNumber) {
        case .sInt8Type,
             .sInt16Type,
             .sInt32Type,
             .sInt64Type,
             .charType,
             .shortType,
             .intType,
             .longType,
             .longLongType,
             .cfIndexType,
             .nsIntegerType:
            return .integer
        default:
            return .floatingPoint
        }
    }

}
