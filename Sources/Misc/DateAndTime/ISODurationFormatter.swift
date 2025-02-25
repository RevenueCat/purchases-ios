//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ISODurationFormatter.swift
//
//  Created by Facundo Menzella on 10/2/25.

import Foundation

/// A representation of an ISO 8601 duration.
///
/// This struct represents both date and time-based components of an ISO 8601 duration string.
/// ISO 8601 durations use the format `PnYnMnWnDTnHnMnS`, where each part is optional:
/// - `P` indicates the duration starts.
/// - `nY` for years.
/// - `nM` for months.
/// - `nW` for weeks.
/// - `nD` for days.
/// - `T` separates the date part from the time part.
/// - `nH` for hours.
/// - `nM` for minutes.
/// - `nS` for seconds.
///
/// Example duration strings:
/// - `"P1Y2M3DT4H5M6S"`: 1 year, 2 months, 3 days, 4 hours, 5 minutes, 6 seconds.
/// - `"P3W"`: 3 weeks.
/// - `"PT15M"`: 15 minutes.
public struct ISODuration: Equatable {
    /// The number of years in the duration.
    ///
    /// Example: For `"P1Y"`, this will be `1`.
    public let years: Int

    /// The number of months in the duration.
    ///
    /// Example: For `"P2M"`, this will be `2`.
    public let months: Int

    /// The number of weeks in the duration.
    ///
    /// Example: For `"P3W"`, this will be `3`.
    public let weeks: Int

    /// The number of days in the duration.
    ///
    /// Example: For `"P4D"`, this will be `4`.
    public let days: Int

    /// The number of hours in the duration.
    ///
    /// Example: For `"PT5H"`, this will be `5`.
    public let hours: Int

    /// The number of minutes in the duration.
    ///
    /// Example: For `"PT6M"`, this will be `6`.
    public let minutes: Int

    /// The number of seconds in the duration.
    ///
    /// Example: For `"PT7S"`, this will be `7`.
    public let seconds: Int
}

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
enum ISODurationFormatter {

    // swiftlint:disable:next line_length
    static let pattern = #"([-+]?)P(?:([-+]?\d+)Y)?(?:([-+]?\d+)M)?(?:([-+]?\d+)W)?(?:([-+]?\d+)D)?(?:T(?:([-+]?\d+)H)?(?:([-+]?\d+)M)?(?:([-+]?\d+)S)?)?"#

    /// Parses an ISO 8601 duration string and returns an `ISODuration` object.
    static func parse(from periodString: String) -> ISODuration? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = periodString as NSString
        let match = regex.firstMatch(
            in: periodString,
            options: [],
            range: NSRange(location: 0, length: nsString.length))

        guard let match = match else {
            print("Failed to parse ISO duration: \(periodString)")
            return nil
        }

        let negate = nsString.substring(with: match.range(at: 1)) == "-" ? -1 : 1

        let years = getIntValue(from: nsString, match: match, at: 2) * negate
        let months = getIntValue(from: nsString, match: match, at: 3) * negate
        let weeks = getIntValue(from: nsString, match: match, at: 4) * negate
        let days = getIntValue(from: nsString, match: match, at: 5) * negate
        let hours = getIntValue(from: nsString, match: match, at: 6) * negate
        let minutes = getIntValue(from: nsString, match: match, at: 7) * negate
        let seconds = getIntValue(from: nsString, match: match, at: 8) * negate

        return ISODuration(
            years: years,
            months: months,
            weeks: weeks,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds)
    }

    /// Converts an `ISODuration` object back to an ISO 8601 duration string.
    static func string(from duration: ISODuration) -> String {
        var result = "P"
        if duration.years != 0 { result += "\(duration.years)Y" }
        if duration.months != 0 { result += "\(duration.months)M" }
        if duration.weeks != 0 { result += "\(duration.weeks)W" }
        if duration.days != 0 { result += "\(duration.days)D" }
        if duration.hours != 0 || duration.minutes != 0 || duration.seconds != 0 {
            result += "T"
            if duration.hours != 0 { result += "\(duration.hours)H" }
            if duration.minutes != 0 { result += "\(duration.minutes)M" }
            if duration.seconds != 0 { result += "\(duration.seconds)S" }
        }
        return result
    }

    private static func getIntValue(from nsString: NSString, match: NSTextCheckingResult, at index: Int) -> Int {
        guard match.range(at: index).location != NSNotFound else {
            return 0
        }
        return Int(nsString.substring(with: match.range(at: index))) ?? 0
    }
}
