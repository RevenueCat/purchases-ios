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

    static func date(fromiso8601SecondsOrMillisecondsString maybeDateString: String?) -> Date? {
        return (Self.iso8601SecondsDateFormatter.date(fromString: maybeDateString)
            ?? Self.iso8601MilliSecondsDateFormatter.date(fromString: maybeDateString))
    }

    func date(fromString maybeDateString: String?) -> Date? {
        guard let dateString = maybeDateString else { return nil }
        return date(from: dateString)
    }

}

private extension DateFormatter {

    static let iso8601MilliSecondsDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()

}
