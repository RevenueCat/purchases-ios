//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ArraySlice_UInt8+Extensions.swift
//
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

extension ArraySlice where Element == UInt8 {

    func toUInt64() -> UInt64 {
        let array = Array(self)
        var result: UInt64 = 0
        for idx in 0..<(array.count) {
            let shiftAmount = UInt((array.count) - idx - 1) * 8
            result += UInt64(array[idx]) << shiftAmount
        }
        return result
    }

    func toInt() -> Int {
        return Int(self.toUInt64())
    }

    func toInt64() -> Int64 {
        return Int64(self.toUInt64())
    }

    func toBool() -> Bool {
        return self.toUInt64() == 1
    }

    func toString() -> String? {
        return String(bytes: self, encoding: .utf8)
    }

    func toDate() -> Date? {
        guard let dateString = String(bytes: Array(self), encoding: .ascii) else { return nil }

        return ISO8601DateFormatter.default.date(from: dateString)
    }

    func toData() -> Data {
        return Data(self)
    }

}
