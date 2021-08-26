//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum OfferingStrings {

    static let cannot_find_product_configuration_error = "Could not find SKProduct for %@ " +
        "\nThere is a problem with your configuration in App Store Connect. " +
        "\nMore info here: https://errors.rev.cat/configuring-products"
    static let completion_handlers_waiting_on_products = "%lu completion handlers waiting on products"
    static let fetching_offerings_error = "Error fetching offerings - %@"
    static let sk_request_failed = "SKRequest failed: %@"
    static let fetching_products_finished = "Products request finished."
    static let fetching_products = "Requesting products from the store with identifiers: %@"
    static let found_existing_product_request = "Found an existing request for products: %@, appending " +
        "to completion"
    static let invalid_product_identifiers = "Invalid Product Identifiers - %@"
    static let list_products = "%@ - %@"
    static let no_cached_offerings_fetching_from_network = "No cached Offerings, fetching from network"
    static let no_cached_requests_and_products_starting_skproduct_request = "No existing requests and " +
        "products not cached, starting SKProducts request for: %@"
    static let offerings_stale_updated_from_network = "Offerings updated from network."
    static let offerings_stale_updating_in_background = "Offerings cache is stale, updating from " +
        "network in background"
    static let offerings_stale_updating_in_foreground = "Offerings cache is stale, updating from " +
        "network in foreground"
    static let products_already_cached = "Skipping products request because products were already " +
        "cached. products: %@"
    static let retrieved_products = "Retrieved SKProducts: "
    static let skproductsrequest_did_finish = "SKProductsRequest did finish"
    static let skproductsrequest_received_response = "SKProductsRequest request received response"
    static let vending_offerings_cache = "Vending Offerings from cache"

}
