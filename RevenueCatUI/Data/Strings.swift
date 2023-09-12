//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Strings.swift
//
//  Created by Nacho Soto on 7/31/23.

import Foundation
import RevenueCat

// swiftlint:disable identifier_name

enum Strings {

    case package_not_subscription(Package)
    case found_multiple_packages_of_same_identifier(String)
    case unrecognized_variable_name(variableName: String)

    case determining_whether_to_display_paywall
    case displaying_paywall
    case not_displaying_paywall
    case dismissing_paywall

    case attempted_to_track_event_with_missing_data

}

extension Strings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .package_not_subscription(package):
            return "Expected package '\(package.identifier)' to be a subscription. " +
            "Type: \(package.packageType.debugDescription)"

        case let .found_multiple_packages_of_same_identifier(identifier):
            return "Found multiple packages with same identifier '\(identifier)'. Will use the first one."

        case let .unrecognized_variable_name(variableName):
            return "Found an unrecognized variable '\(variableName)'. It will be replaced with an empty string.\n" +
            "See the docs for more information: https://www.revenuecat.com/docs/paywalls#variables"

        case .determining_whether_to_display_paywall:
            return "Determining whether to display paywall"

        case .displaying_paywall:
            return "Condition met: will display paywall"

        case .not_displaying_paywall:
            return "Condition not met: will not display paywall"

        case .dismissing_paywall:
            return "Dismissing PaywallView"

        case .attempted_to_track_event_with_missing_data:
            return "Attempted to track event with missing data"
        }
    }

}
