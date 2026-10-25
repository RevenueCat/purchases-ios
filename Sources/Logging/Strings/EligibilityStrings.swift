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
    case clearing_intro_eligibility_cache
    case unable_to_get_intro_eligibility_for_user(error: Error)
    case check_eligibility_no_identifiers
    case check_eligibility_failed(productIdentifier: String, error: Error)
    case sk2_intro_eligibility_too_slow
    case waiting_for_intro_eligibility(_ identifiers: Set<String>)
    case product_lookup_started(requestID: String, identifiers: Set<String>)
    case product_lookup_finished(requestID: String, identifiers: Set<String>, missingIdentifiers: Set<String>,
                                 duration: TimeInterval)
    case product_lookup_failed(requestID: String, error: Error, duration: TimeInterval)
    case subscription_group_check_started(requestID: String, groupID: String)
    case subscription_group_check_finished(requestID: String, groupID: String, eligible: Bool, duration: TimeInterval)
    case check_finished(requestID: String, result: [String: IntroEligibility], duration: TimeInterval)
    case delivering_intro_eligibility(result: [String: IntroEligibility], duration: TimeInterval)

}

extension EligibilityStrings: LogMessage {

    var description: String {
        switch self {
        case let .found_cached_eligibility_for_products(identifiers):
            return "Found cached trial or intro eligibility for products: \(identifiers)"

        case let .caching_intro_eligibility_for_products(identifiers):
            return "Caching trial or intro eligibility for products: \(identifiers)"

        case .clearing_intro_eligibility_cache:
            return "Detected active subscriptions changed. Clearing trial or intro eligibility cache."

        case let .unable_to_get_intro_eligibility_for_user(error):
            return "Unable to get intro eligibility for appUserID: \(error.localizedDescription)"

        case .check_eligibility_no_identifiers:
            return "Requested trial or introductory price eligibility with no identifiers. " +
            "This is likely a program error."

        case let .check_eligibility_failed(productIdentifier, error):
            return "Error checking discount eligibility for product '\(productIdentifier)': \(error).\n" +
            "Will be considered not eligible."

        case .sk2_intro_eligibility_too_slow:
            return "StoreKit 2 intro eligibility took longer than expected to determine"

        case let .waiting_for_intro_eligibility(identifiers):
            return "Waiting for an in-flight intro eligibility check for products: \(identifiers.sorted())"

        case let .product_lookup_started(requestID, identifiers):
            return "Intro eligibility (\(requestID)): starting product lookup for \(identifiers.sorted())"

        case let .product_lookup_finished(requestID, identifiers, missingIdentifiers, duration):
            return "Intro eligibility (\(requestID)): product lookup finished in \(duration)s. " +
                "Products: \(identifiers.sorted()); missing products: \(missingIdentifiers.sorted())"

        case let .product_lookup_failed(requestID, error, duration):
            let nsError = error as NSError
            return "Intro eligibility (\(requestID)): product lookup failed after \(duration)s. " +
                "Error: \(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)"

        case let .subscription_group_check_started(requestID, groupID):
            return "Intro eligibility (\(requestID)): starting StoreKit check for subscription group '\(groupID)'"

        case let .subscription_group_check_finished(requestID, groupID, eligible, duration):
            return "Intro eligibility (\(requestID)): StoreKit check for subscription group '\(groupID)' " +
                "finished in \(duration)s; eligible=\(eligible)"

        case let .check_finished(requestID, result, duration):
            return "Intro eligibility (\(requestID)): check finished in \(duration)s. " +
                "Results: \(Self.describe(result))"

        case let .delivering_intro_eligibility(result, duration):
            return "Delivering intro eligibility results after \(duration)s waiting for the main queue. " +
                "Results: \(Self.describe(result))"
        }
    }

    var category: String { return "eligibility" }

}

private extension EligibilityStrings {

    static func describe(_ result: [String: IntroEligibility]) -> [String] {
        return result.map { "\($0.key): \($0.value.status.description)" }.sorted()
    }

}
