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
    /// numeric Swift types. Core Foundation preserves booleans, while `objCType` preserves the numeric storage
    /// type used by `JSONSerialization`.
    var jsonNumberKind: JSONNumberKind {
        // CoreFoundation booleans (`kCFBooleanTrue` / `kCFBooleanFalse`)
        // are bridged to NSNumber but carry the boolean type ID, so
        // `CFGetTypeID` is the only reliable way to tell them apart from
        // a JSON integer of value 0 or 1.
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return .boolean
        }

        // `objCType` reports the NSNumber storage type using Objective-C
        // type encodings. See:
        // swiftlint:disable:next line_length
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        // JSONSerialization typically uses 'q' for whole numbers and 'd'
        // for fractional ones — that's how we keep `100` → .int(100) and
        // `100.0` → .float(100.0).
        let type = String(cString: self.objCType)
        switch type {
        case "c", "i", "s", "l", "q", "C", "I", "S", "L", "Q":
            return .integer
        default:
            return .floatingPoint
        }
    }

}
