//
//  OfferingStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCOfferingStrings) public class OfferingStrings: NSObject {
    @objc public var cannot_find_product: String { "Could not find SKProduct for %@ \nThere is a problem with your configuration in App Store Connect. \nMore info here: http://errors.rev.cat/products-empty"} //appleWarning
    @objc public var completion_handler_waiting_on_products: String { "%lu completion handlers waiting on products" } //debug
    @objc public var fetching_offerings_error: String { "Error fetching offerings - %@" } //appleError
    @objc public var fetching_products_failed: String { "SKRequest failed: %@" }  //appleError
    @objc public var fetching_products_finished: String { "Products request finished" }  //debug
    @objc public var fetching_products: String { "Requesting products from the store with identifiers: %@" } //debug
    @objc public var found_existing_product_request: String { "Found an existing request for products: %@, appending to completion" }  //debug
    @objc public var invalid_product_identifiers: String { "Invalid Product Identifiers - %@" } //appleWarning
    @objc public var list_products: String { "%@ - %@" } //purchase
    @objc public var no_cached_offerings_fetching_network: String { "No cached Offerings, fetching from network" } //debug
    @objc public var offerings_stale_updated_network: String { "Offerings updated from network." } // rcSuccess
    @objc public var offerings_stale_updating_background: String { "Offerings cache is stale, updating from network in background" } //debug
    @objc public var offerings_stale_updating_foreground: String { "Offerings cache is stale, updating from network in foreground" } //debug
    @objc public var products_already_cached: String { "Skipping products request because products were already cached. products: %@" } //debug
    @objc public var retrived_products: String { "Retrived SKProducts: "  } //purchase
    @objc public var starting_skproduct_request: String { "No existing requests and products not cached, starting SKProducts request for: %@" } //debug
    @objc public var vending_offerings_cache: String { "Vending Offerings from cache" } //debug
}
