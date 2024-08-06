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

    case product_already_subscribed

    case determining_whether_to_display_paywall
    case displaying_paywall
    case not_displaying_paywall
    case dismissing_paywall
    case tier_has_no_available_products_for_paywall(String)

    case attempted_to_track_event_with_missing_data

    case image_starting_request(URL)
    case image_result(Result<(), ImageLoader.Error>)

    case restoring_purchases
    case restored_purchases
    case restore_purchases_with_empty_result
    case setting_restored_customer_info

    case executing_purchase_logic
    case executing_external_purchase_logic
    case executing_restore_logic
    case executing_external_restore_logic

    case no_price_format_priceFormatter_unavailable
    case no_price_format_priceString_incompatible
    case no_price_round_priceFormatter_nil
    case no_price_round_priceString_incompatible
    case no_price_round_formatter_failed
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

        case .product_already_subscribed:
            return "User is already subscribed to this product. Ignoring."

        case .determining_whether_to_display_paywall:
            return "Determining whether to display paywall"

        case .displaying_paywall:
            return "Condition met: will display paywall"

        case .not_displaying_paywall:
            return "Condition not met: will not display paywall"

        case .dismissing_paywall:
            return "Dismissing PaywallView"

        case let .tier_has_no_available_products_for_paywall(tierName):
            return "Tier '\(tierName)' has no available products and will be removed from the paywall."

        case .attempted_to_track_event_with_missing_data:
            return "Attempted to track event with missing data"

        case let .image_starting_request(url):
            return "Starting request for image: '\(url)'"

        case let .image_result(result):
            switch result {
            case .success:
                return "Successfully loaded image"
            case let .failure(error):
                return "Failed loading image: \(error)"
            }

        case .restoring_purchases:
            return "Restoring purchases"

        case .restored_purchases:
            return "Restored purchases successfully with unlocked subscriptions"

        case .restore_purchases_with_empty_result:
            return "Restored purchases successfully with no subscriptions"

        case .setting_restored_customer_info:
            return "Setting restored customer info"

        case .executing_external_purchase_logic:
            return "Will execute custom StoreKit purchase logic provided by your app. " +
            "No StoreKit purchasing logic will be performed by RevenueCat. " +
            "You must have initialized your `PaywallView` appropriately."

        case .executing_purchase_logic:
            return "Will execute purchase logic provided by RevenueCat."

        case .executing_restore_logic:
            return "Will execute restore purchases logic provided by RevenueCat."

        case .executing_external_restore_logic:
            return "Will execute custom StoreKit restore purchases logic provided by your app. " +
            "No StoreKit restore purchases logic will be performed by RevenueCat. " +
            "You must have initialized your `PaywallView` appropriately."

        case .no_price_format_priceFormatter_unavailable:
            return "Could not determine price format because priceFormatter is unavailable."

        case .no_price_format_priceString_incompatible:
            return " Could not determine price format because priceString is incompatible."

        case .no_price_round_priceFormatter_nil:
            return " Could not round price because priceFormatter is nil."

        case .no_price_round_priceString_incompatible:
            return "Could not round price because priceString is incompatible."

        case .no_price_round_formatter_failed:
            return "Could not round price because formatter failed to round price."
        }
    }

}
