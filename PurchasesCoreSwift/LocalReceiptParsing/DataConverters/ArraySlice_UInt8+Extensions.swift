//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

extension ArraySlice where Element == UInt8 {
    func toUInt() -> UInt {
        let array = Array(self)
        var result: UInt = 0
        for idx in 0..<(array.count) {
            let shiftAmount = UInt((array.count) - idx - 1) * 8
            result += UInt(array[idx]) << shiftAmount
        }
        return result
    }

    func toInt() -> Int {
        return Int(self.toUInt())
    }

    func toBool() -> Bool {
        return self.toUInt() == 1
    }

    func toString() -> String? {
        return String(bytes: self, encoding: .utf8)
    }

    func toDate(dateFormatter: ISO3601DateFormatter) -> Date? {
        return dateFormatter.date(fromBytes: self)
    }

    func toData() -> Data {
        return Data(self)
    }
}
