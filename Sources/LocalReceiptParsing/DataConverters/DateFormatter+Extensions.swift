//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DateFormatter+Extensions.swift
//
//  Created by Nacho Soto on 12/14/22.

import Foundation

/// A type that can convert from and to `Dates`.
protocol DateFormatterType {

    func string(from date: Date) -> String
    func date(from string: String) -> Date?

}

extension DateFormatter: DateFormatterType {}
extension ISO8601DateFormatter: DateFormatterType {}

extension DateFormatterType {

    func date(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return date(from: dateString)
    }

}

extension ISO8601DateFormatter {

    /// This behaves like a traditional `DateFormatter` with format
    /// `yyyy-MM-dd'T'HH:mm:ssZ"`, so milliseconds are optional.
    static let `default`: DateFormatterType = {
        final class Formatter: DateFormatterType {
            func date(from string: String) -> Date? {
                return ISO8601DateFormatter.withMilliseconds.date(from: string)
                    ?? ISO8601DateFormatter.noMilliseconds.date(from: string)
            }

            func string(from date: Date) -> String {
                return ISO8601DateFormatter.withMilliseconds.string(from: date)
            }
        }

        return Formatter()
    }()

}

private extension ISO8601DateFormatter {

    static let withMilliseconds: DateFormatterType = {
        if #available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

            return formatter
        } else {
            // See https://github.com/RevenueCat/purchases-ios/pull/2037
            // `.withFractionalSeconds` makes iOS 11 crash.
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            return dateFormatter
        }
    }()

    static let noMilliseconds: DateFormatterType = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime
        ]

        return formatter
    }()

}
