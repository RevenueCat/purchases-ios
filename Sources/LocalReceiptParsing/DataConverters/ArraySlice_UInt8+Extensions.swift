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
        if let fastParsed = toDateFastParse() {
            // This approach is around ~60% faster than `ISO8601DateFormatter.default`
            return fastParsed
        }
        guard let dateString = String(bytes: Array(self), encoding: .ascii) else { return nil }

        return ISO8601DateFormatter.default.date(from: dateString)
    }

    func toData() -> Data {
        return Data(self)
    }

}

private extension ArraySlice where Element == UInt8 {

    static let toDateCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    func toDateFastParse() -> Date? {
        // expected format 2015-08-10T07:19:32Z
        guard count == 20 else { return nil }
        let asciiZero: UInt8 = 48
        let asciiNine: UInt8 = 57
        let asciiDash: UInt8 = 45
        let asciiColon: UInt8 = 58
        let asciiT: UInt8 = 84
        let asciiZ: UInt8 = 90
        let limits: [(min: UInt8, max: UInt8)] = [
            (asciiZero, asciiNine), (asciiZero, asciiNine), (asciiZero, asciiNine), (asciiZero, asciiNine), // year
            (asciiDash, asciiDash),
            (asciiZero, asciiNine), (asciiZero, asciiNine), // month
            (asciiDash, asciiDash),
            (asciiZero, asciiNine), (asciiZero, asciiNine), // day
            (asciiT, asciiT),
            (asciiZero, asciiNine), (asciiZero, asciiNine), // hour
            (asciiColon, asciiColon),
            (asciiZero, asciiNine), (asciiZero, asciiNine), // minute
            (asciiColon, asciiColon),
            (asciiZero, asciiNine), (asciiZero, asciiNine), // second
            (asciiZ, asciiZ)
        ]
        for (character, limit) in zip(self, limits) {
            guard limit.min <= character,
                  character <= limit.max else { return nil }
        }

        let year = toDateParseAsciiNumber(from: 0, to: 4)
        let month = toDateParseAsciiNumber(from: 5, to: 7)
        guard 1 <= month,
              month <= 12 else { return nil }
        let day = toDateParseAsciiNumber(from: 8, to: 10)
        guard 1 <= day,
              day <= 31 else { return nil }
        let hour = toDateParseAsciiNumber(from: 11, to: 13)
        guard 0 <= hour,
              hour <= 23 else { return nil }
        let minute = toDateParseAsciiNumber(from: 14, to: 16)
        guard 0 <= minute,
              minute <= 59 else { return nil }
        let second = toDateParseAsciiNumber(from: 17, to: 19)
        guard 0 <= second,
              second <= 59 else { return nil }

        let components = DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        )
        return Self.toDateCalendar.date(from: components)
    }

    func toDateParseAsciiNumber(from: Int, to: Int) -> Int { // swiftlint:disable:this identifier_name
        let asciiZero: UInt8 = 48
        var index = from + startIndex
        let end = to + startIndex
        var result = 0
        while index < end {
            let digit = self[index] - asciiZero
            result = result * 10 + Int(digit)
            index += 1
        }
        return result
    }

}
