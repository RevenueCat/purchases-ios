//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EligibilityStrings.swift
//
//  Created by Nacho Soto on 10/31/22.

import Foundation

// swiftlint:disable identifier_name

enum EligibilityStrings {

    case found_cached_eligibility_for_products(_ identifiers: Set<String>)
    case caching_intro_eligibility_for_products(_ identifiers: Set<String>)
    case unable_to_get_intro_eligibility_for_user(error: Error)
    case check_eligibility_no_identifiers
    case check_eligibility_failed(productIdentifier: String, error: Error)
}

extension EligibilityStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .found_cached_eligibility_for_products(identifiers):
            return "Found cached trial or intro eligibility for products: \(identifiers)"

        case let .caching_intro_eligibility_for_products(identifiers):
            return "Caching trial or intro eligibility for products: \(identifiers)"

        case let .unable_to_get_intro_eligibility_for_user(error):
            return "Unable to get intro eligibility for appUserID: \(error.localizedDescription)"

        case .check_eligibility_no_identifiers:
            return "Requested trial or introductory price eligibility with no identifiers. " +
            "This is likely a program error."

        case let .check_eligibility_failed(productIdentifier, error):
            return "Error checking discount eligibility for product '\(productIdentifier)': \(error).\n" +
            "Will be considered not eligible."
        }
    }

}
