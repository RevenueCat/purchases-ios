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
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

/// A type that can convert from and to `Dates`.
public protocol DateFormatterType {

    /// Returns a date representation of a specified string that the system interprets
    /// using the receiver’s current settings.
    func string(from date: Date) -> String
    /// Returns a string representation of a specified date that the system formats
    /// using the receiver’s current settings.
    func date(from string: String) -> Date?

    /// Creates a `JSONDecoder.DateDecodingStrategy` from `self`
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }
}

extension DateFormatter: DateFormatterType {

    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return .formatted(self)
    }

}

extension ISO8601DateFormatter: DateFormatterType {

    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return .iso8601
    }

}

internal extension ISO8601DateFormatter {

    private static let withMilliseconds: DateFormatterType = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter
    }()

    private static let noMilliseconds: DateFormatterType = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime
        ]

        return formatter
    }()

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

            var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
                return .iso8601
            }
        }

        return Formatter()
    }()

}

internal extension DateFormatterType {

    func date(from maybeDateString: String?) -> Date? {
        guard let dateString = maybeDateString else { return nil }
        return date(from: dateString)
    }

}
