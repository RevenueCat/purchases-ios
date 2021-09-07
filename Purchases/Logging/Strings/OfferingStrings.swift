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
import StoreKit

// swiftlint:disable identifier_name
enum OfferingStrings {

    case cannot_find_product_configuration_error(identifiers: Set<String>)

    case fetching_offerings_error(error: String)

    case found_existing_product_request(identifiers: Set<String>)

    case no_cached_offerings_fetching_from_network

    case no_cached_requests_and_products_starting_skproduct_request(identifiers: Set<String>)

    case offerings_stale_updated_from_network

    case offerings_stale_updating_in_background

    case offerings_stale_updating_in_foreground

    case products_already_cached(identifiers: Set<String>)

    case sk_request_failed(error: Error)

    case skproductsrequest_did_finish

    case skproductsrequest_received_response

    case vending_offerings_cache

    case retrieved_products(products: [SKProduct])

    case list_products(productIdentifier: String, product: SKProduct)

    case invalid_product_identifiers(identifiers: Set<String>)

    case fetching_products_finished

    case fetching_products(identifiers: Set<String>)

    case completion_handlers_waiting_on_products(handlersCount: Int)

}

extension OfferingStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .cannot_find_product_configuration_error(let identifiers):
            return "Could not find SKProduct for \(identifiers) " +
                "\nThere is a problem with your configuration in App Store Connect. " +
                "\nMore info here: https://errors.rev.cat/configuring-products"

        case .fetching_offerings_error(let error):
            return "Error fetching offerings - \(error)"

        case .found_existing_product_request(let identifiers):
            return "Found an existing request for products: \(identifiers), appending " +
                "to completion"

        case .no_cached_offerings_fetching_from_network:
            return "No cached Offerings, fetching from network"

        case .no_cached_requests_and_products_starting_skproduct_request(let identifiers):
            return "No existing requests and " +
                "products not cached, starting SKProducts request for: \(identifiers)"

        case .offerings_stale_updated_from_network:
            return "Offerings updated from network."

        case .offerings_stale_updating_in_background:
            return "Offerings cache is stale, updating from " +
                "network in background"

        case .offerings_stale_updating_in_foreground:
            return "Offerings cache is stale, updating from " +
                "network in foreground"

        case .products_already_cached(let identifiers):
            return "Skipping products request because products were already " +
                "cached. products: \(identifiers)"

        case .sk_request_failed(let error):
            return "SKRequest failed: \(error.localizedDescription)"

        case .skproductsrequest_did_finish:
            return "SKProductsRequest did finish"

        case .skproductsrequest_received_response:
            return "SKProductsRequest request received response"

        case .vending_offerings_cache:
            return "Vending Offerings from cache"

        case .retrieved_products(let products):
            return "Retrieved SKProducts: \(products)"

        case let .list_products(productIdentifier, product):
            return "\(productIdentifier) - \(product)"

        case .invalid_product_identifiers(let identifiers):
            return "Invalid Product Identifiers - \(identifiers)"

        case .fetching_products_finished:
            return "Products request finished."

        case .fetching_products(let identifiers):
            return "Requesting products from the store with identifiers: \(identifiers)"

        case .completion_handlers_waiting_on_products(let handlersCount):
            return "\(handlersCount) completion handlers waiting on products"

        }
    }

}
