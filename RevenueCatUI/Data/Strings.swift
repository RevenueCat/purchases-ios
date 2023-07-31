//
//  Strings.swift
//  
//
//  Created by Nacho Soto on 7/31/23.
//

import Foundation
import RevenueCat

// swiftlint:disable variable_name

enum Strings {

    case found_multiple_packages_of_same_type(PackageType)
    case could_not_find_content_for_variable(variableName: String)

    case determining_whether_to_display_paywall
    case displaying_paywall
    case not_displaying_paywall

}

extension Strings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .found_multiple_packages_of_same_type(type):
            return "Found multiple \(type) packages. Will use the first one."

        case let .could_not_find_content_for_variable(variableName):
            return "Couldn't find content for variable '\(variableName)'"

        case .determining_whether_to_display_paywall:
            return "Determining whether to display paywall"

        case .displaying_paywall:
            return "Condition met: will display paywall"

        case .not_displaying_paywall:
            return "Condition not met: will not display paywall"
        }
    }

}
