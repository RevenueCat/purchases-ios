//
//  OfferingStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCOfferingStrings) public class OfferingStrings: NSObject {
    @objc public var cannot_find_product_configuration_error: String { "Could not find SKProduct for %@ " +
        "\nThere is a problem with your configuration in App Store Connect. " +
        "\nMore info here: https://errors.rev.cat/configuring-products"}
    @objc public var completion_handlers_waiting_on_products: String { "%lu completion handlers waiting on products" }
    @objc public var fetching_offerings_error: String { "Error fetching offerings - %@" }
    @objc public var fetching_products_failed: String { "SKRequest failed: %@" }
    @objc public var fetching_products_finished: String { "Products request finished." }
    @objc public var fetching_products: String { "Requesting products from the store with identifiers: %@" }
    @objc public var found_existing_product_request: String { "Found an existing request for products: %@, appending " +
        "to completion" }
    @objc public var invalid_product_identifiers: String { "Invalid Product Identifiers - %@" }
    @objc public var list_products: String { "%@ - %@" }
    @objc public var no_cached_offerings_fetching_from_network: String { "No cached Offerings, fetching from network" }
    @objc public var no_cached_requests_and_products_starting_skproduct_request: String { "No existing requests and " +
        "products not cached, starting SKProducts request for: %@" }
    @objc public var offerings_stale_updated_from_network: String { "Offerings updated from network." }
    @objc public var offerings_stale_updating_in_background: String { "Offerings cache is stale, updating from " +
        "network in background" }
    @objc public var offerings_stale_updating_in_foreground: String { "Offerings cache is stale, updating from " +
        "network in foreground" }
    @objc public var products_already_cached: String { "Skipping products request because products were already " +
        "cached. products: %@" }
    @objc public var retrieved_products: String { "Retrieved SKProducts: "  }
    @objc public var skproductsrequest_did_finish: String { "SKProductsRequest did finish" }
    @objc public var skproductsrequest_received_response: String { "SKProductsRequest request received response" }
    @objc public var vending_offerings_cache: String { "Vending Offerings from cache" }
}
