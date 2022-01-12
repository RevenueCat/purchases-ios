//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Date+Extensions.swift
//
//  Created by Josh Holtz on 6/28/21.
//

import Foundation

extension NSDate {

    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }
}

extension Date {

    func rc_millisecondsSince1970AsUInt64() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000.0)
    }

    // swiftlint:disable:next function_parameter_count
    static func from(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) throws -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        guard let date = calendar.date(from: dateComponents) else {
            throw DateExtensionsError.invalidDateComponents(dateComponents)
        }
        return date
    }
}
