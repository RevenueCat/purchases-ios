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

    case no_price_format_price_formatter_unavailable
    case no_price_format_price_string_incompatible
    case no_price_round_price_formatter_nil
    case no_price_round_price_string_incompatible
    case no_price_round_formatter_failed

    case invalid_color_string(String)
    case paywall_view_model_construction_failed(Error)
    case paywall_contains_no_localization_data
    case paywall_could_not_find_localization(String)
    case paywall_could_not_find_package(String)
    case paywall_could_not_find_default_package
    case paywall_could_not_find_any_packages
    case paywall_invalid_url(String)
    case no_in_app_browser_tvos
    case failed_to_open_url_external_browser(String)
    case successfully_opened_url_external_browser(String)
    case failed_to_open_url_deep_link(String)
    case successfully_opened_url_deep_link(String)
    case no_selected_package_found
    case no_web_checkout_url_found

    // Customer Center
    case could_not_find_subscription_information
    case could_not_offer_for_any_active_subscriptions
    case could_not_offer_for_active_subscriptions(String, String)
    case error_fetching_promotional_offer(Error)
    case promo_offer_not_loaded
    case purchasing_promotional_offer(String, String)
    case promo_offer_purchase_cancelled(String, String)
    case promo_offer_purchase_succeeded(String, String, String)
    case promo_offer_purchase_failed(String, String, Error)
    case could_not_determine_type_of_custom_url
    case active_product_is_not_apple_loading_without_product_information(Store)
    case could_not_find_product_loading_without_product_information(String)
    case promo_offer_not_eligible_for_product(String, String)
    case could_not_find_target_product(String, String)
    case could_not_find_discount_for_target_product(String, String)

    // UIConfigProvider
    case localizationNotFound(identifier: String)
    case fontMappingNotFound(name: String)
    case customFontFailedToLoad(fontName: String)
    case googleFontsNotSupported
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

        case .no_price_format_price_formatter_unavailable:
            return "Could not determine price format because price formatter is unavailable."

        case .no_price_format_price_string_incompatible:
            return "Could not determine price format because price string is incompatible."

        case .no_price_round_price_formatter_nil:
            return "Could not round price because price formatter is nil."

        case .no_price_round_price_string_incompatible:
            return "Could not round price because price string is incompatible."

        case .no_price_round_formatter_failed:
            return "Could not round price because formatter failed to round price."

        case .paywall_view_model_construction_failed(let error):
            return "Paywall view model construction failed: \(error)\n" +
            "Will use fallback paywall."

        case .paywall_could_not_find_localization(let string):
            return "Could not find paywall localization data for \(string)"

        case .paywall_contains_no_localization_data:
            return "Paywall contains no localization data."

        case .paywall_could_not_find_package(let identifier):
            return "Could not find package \(identifier) for paywall. This package will not show in the paywall. " +
            "This could be caused by a package that doesn't have a product on this platform or the product might not " +
            " be available for this region."

        case .paywall_could_not_find_default_package:
            return "Could not find default package for paywall. Using first package instead. " +
            "This package will not show in the paywall. This could be caused by a package that doesn't have a " +
            "product on this platform or the product might not be available for this region."

        case .paywall_could_not_find_any_packages:
            return "Could not find any packages for the paywall"

        case .paywall_invalid_url(let urlLid):
            return "No valid URL is configured for \(urlLid)"

        case .no_in_app_browser_tvos:
            return "Opening URL in external browser, as tvOS does not support in-app browsers."

        case .invalid_color_string(let colorString):
            return "Invalid hex color string: \(colorString)"

        case .could_not_find_subscription_information:
            return "Could not find information for an active subscription"

        case let .error_fetching_promotional_offer(error):
            return "Error fetching promotional offer for active product: \(error)"

        case .promo_offer_not_loaded:
            return "Promotional offer details not loaded"

        case let .purchasing_promotional_offer(productId, offerId):
            return "Attempting promotional offer purchase for product '\(productId)' with offer '\(offerId)'."

        case let .promo_offer_purchase_cancelled(productId, offerId):
            return "Promotional offer purchase cancelled for product '\(productId)' with offer '\(offerId)'."

        case let .promo_offer_purchase_succeeded(productId, offerId, transactionId):
            return "Promotional offer purchase succeeded for product '\(productId)' with offer '\(offerId)'. " +
            "Transaction: \(transactionId)"

        case let .promo_offer_purchase_failed(productId, offerId, error):
            return "Promotional offer purchase failed for product '\(productId)' with offer '\(offerId)': \(error)"

        case .could_not_offer_for_any_active_subscriptions:
            return "Could not find offer with id for any active subscription"

        case .could_not_offer_for_active_subscriptions(let discount, let subscription):
            return "Could not find offer with id \(discount) for active subscription \(subscription)"

        case .could_not_determine_type_of_custom_url:
            return "Could not determine the type of custom URL, the URL will be opened externally."

        case .active_product_is_not_apple_loading_without_product_information(let store):
            return "Active product for user is not an Apple subscription (\(store))." +
            " Loading without product information."

        case .could_not_find_product_loading_without_product_information(let product):
            return "Could not find product with id \(product). Loading without product information."

        case let .promo_offer_not_eligible_for_product(promoOfferId, productId):
            return """
                User not eligible for promo with id '\(promoOfferId)'. Check eligibility configuration in the dashboard,
                and make sure the user has an active/expired subscription for the product with id '\(productId)'."
            """

        case let .could_not_find_target_product(targetProductId, productIdentifier):
            return "Could not find target product with id \(targetProductId) " +
            "for active subscription \(productIdentifier)"

        case let .could_not_find_discount_for_target_product(offerIdentifier, productIdentifier):
            return "Could not find offer with id \(offerIdentifier) for target product \(productIdentifier)"

        case .failed_to_open_url_external_browser(let url):
            return "Failed to open URL in external browser: \(url)"

        case .successfully_opened_url_external_browser(let url):
            return "Successfully opened URL in external browser: \(url)"

        case .failed_to_open_url_deep_link(let url):
            return "Failed to open URL as deep link: \(url)"

        case .successfully_opened_url_deep_link(let url):
            return "Successfully opened URL as deep link: \(url)"

        case .no_selected_package_found:
            return "No selected package found."

        case .no_web_checkout_url_found:
            return "No web checkout url found."

        case .localizationNotFound(let identifier):
            return "Could not find localizations for '\(identifier)'"
        case .fontMappingNotFound(let name):
            return "Mapping for '\(name)' could not be found. Falling back to system font."
        case .customFontFailedToLoad(let fontName):
            return "Custom font '\(fontName)' could not be loaded. Falling back to system font."
        case .googleFontsNotSupported:
            return "Google Fonts are not supported on this platform"
        }
    }

}
