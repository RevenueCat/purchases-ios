//
// Created by Andrés Boedo on 8/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

enum DateExtensionsError: Error {
    case notValidDateFromComponents
}
    
extension Date {

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
        guard let date = calendar.date(from: dateComponents) else { throw DateExtensionsError.notValidDateFromComponents }
        return date
    }
}
