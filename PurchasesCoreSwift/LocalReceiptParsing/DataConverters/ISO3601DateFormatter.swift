//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct ISO3601DateFormatter {
    static let shared = ISO3601DateFormatter()

    private let secondsDateFormatter = DateFormatter()
    private let milisecondsDateFormatter = DateFormatter()

    private init() {
        secondsDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
        milisecondsDateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ"
    }

    func date(fromBytes bytes: ArraySlice<UInt8>) -> Date? {
        guard let dateString = String(bytes: Array(bytes), encoding: .ascii) else { return nil }
        return (secondsDateFormatter.date(from: dateString)
            ?? milisecondsDateFormatter.date(from: dateString))
    }
}
