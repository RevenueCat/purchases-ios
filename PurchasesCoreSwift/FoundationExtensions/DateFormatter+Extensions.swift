//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let iso8601SecondsDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()

    static let iso8601MilliSecondsDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()

    func iso8601SecondsOrMillisecondsDate(fromBytes bytes: ArraySlice<UInt8>) -> Date? {
        guard let dateString = String(bytes: Array(bytes), encoding: .ascii) else { return nil }
        return (Self.iso8601SecondsDateFormatter.date(from: dateString)
            ?? Self.iso8601MilliSecondsDateFormatter.date(from: dateString))
    }

    func date(fromString maybeDateString: String?) -> Date? {
        guard let dateString = maybeDateString else { return nil }
        return date(from: dateString)
    }
}
