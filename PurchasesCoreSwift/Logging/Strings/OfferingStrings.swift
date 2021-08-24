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
class OfferingStrings {

    var cannot_find_product_configuration_error: String { "Could not find SKProduct for %@ " +
        "\nThere is a problem with your configuration in App Store Connect. " +
        "\nMore info here: https://errors.rev.cat/configuring-products"}
    var completion_handlers_waiting_on_products: String { "%lu completion handlers waiting on products" }
    var fetching_offerings_error: String { "Error fetching offerings - %@" }
    var sk_request_failed: String { "SKRequest failed: %@" }
    var fetching_products_finished: String { "Products request finished." }
    var fetching_products: String { "Requesting products from the store with identifiers: %@" }
    var found_existing_product_request: String { "Found an existing request for products: %@, appending " +
        "to completion" }
    var invalid_product_identifiers: String { "Invalid Product Identifiers - %@" }
    var list_products: String { "%@ - %@" }
    var no_cached_offerings_fetching_from_network: String { "No cached Offerings, fetching from network" }
    var no_cached_requests_and_products_starting_skproduct_request: String { "No existing requests and " +
        "products not cached, starting SKProducts request for: %@" }
    var offerings_stale_updated_from_network: String { "Offerings updated from network." }
    var offerings_stale_updating_in_background: String { "Offerings cache is stale, updating from " +
        "network in background" }
    var offerings_stale_updating_in_foreground: String { "Offerings cache is stale, updating from " +
        "network in foreground" }
    var products_already_cached: String { "Skipping products request because products were already " +
        "cached. products: %@" }
    var retrieved_products: String { "Retrieved SKProducts: "  }
    var skproductsrequest_did_finish: String { "SKProductsRequest did finish" }
    var skproductsrequest_received_response: String { "SKProductsRequest request received response" }
    var vending_offerings_cache: String { "Vending Offerings from cache" }

}
