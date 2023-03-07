//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by Andrés Boedo on 8/7/20.
//

import Foundation

enum DateExtensionsError: Error {

    case invalidDateComponents(_ dateComponents: DateComponents)

}

extension DateExtensionsError: CustomStringConvertible {

    var description: String {
        switch self {
        case .invalidDateComponents(let dateComponents):
            return "invalid date components: \(dateComponents.description)"
        }
    }

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
        guard let date = calendar.date(from: dateComponents) else {
            throw DateExtensionsError.invalidDateComponents(dateComponents)
        }
        return date
    }

}
