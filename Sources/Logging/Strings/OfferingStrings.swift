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
    case fetching_offerings_error(error: OfferingsManager.Error, underlyingError: Error?)
    case fetching_offerings_failed_server_down
    case found_existing_product_request(identifiers: Set<String>)
    case no_cached_offerings_fetching_from_network
    case offerings_stale_updated_from_network
    case offerings_stale_updating_in_background
    case offerings_stale_updating_in_foreground
    case products_already_cached(identifiers: Set<String>)
    case product_cache_invalid_for_storefront_change
    case vending_offerings_cache_from_memory
    case vending_offerings_cache_from_disk
    case retrieved_products(products: [SKProduct])
    case list_products(productIdentifier: String, product: SKProduct)
    case invalid_product_identifiers(identifiers: Set<String>)
    case fetching_products_finished
    case fetching_products(identifiers: Set<String>)
    case completion_handlers_waiting_on_products(handlersCount: Int)
    case configuration_error_products_not_found
    case configuration_error_no_products_for_offering
    case offering_empty(offeringIdentifier: String)
    case product_details_empty_title(productIdentifier: String)
    case unknown_package_type(Package)
    case custom_package_type(Package)
    case overriding_package(old: String, new: String)

}

extension OfferingStrings: LogMessage {

    var description: String {
        switch self {
        case .cannot_find_product_configuration_error(let identifiers):
            return "Could not find products with identifiers: \(identifiers)." +
                "\nThere is a problem with your configuration in App Store Connect. " +
                "\nMore info here: https://errors.rev.cat/configuring-products"

        case let .fetching_offerings_error(error, underlyingError):
            var result = "Error fetching offerings - \(error.localizedDescription)"

            if let message = error.errorDescription {
                result += "\n\(message)"
            }

            if let underlyingError = underlyingError {
                result += "\nUnderlying error: \(underlyingError.localizedDescription)"
            }

            return result

        case .fetching_offerings_failed_server_down:
            return "Error fetching offerings: server appears down"

        case .found_existing_product_request(let identifiers):
            return "Found an existing request for products: \(identifiers), appending " +
                "to completion"

        case .no_cached_offerings_fetching_from_network:
            return "No cached Offerings, fetching from network"

        case .offerings_stale_updated_from_network:
            return "Offerings updated from network."

        case .offerings_stale_updating_in_background:
            return "Offerings cache is stale, updating from " +
                "network in background"

        case .offerings_stale_updating_in_foreground:
            return "Offerings cache is stale, updating from " +
                "network in foreground"

        case let .products_already_cached(identifiers):
            return "Skipping products request for these products because they were already " +
                "cached: \(identifiers)"

        case .product_cache_invalid_for_storefront_change:
            return "Storefront change detected. Invalidating and re-fetching product cache."

        case .vending_offerings_cache_from_memory:
            return "Vending Offerings from memory cache"

        case .vending_offerings_cache_from_disk:
            return "Vending Offerings from disk cache"

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

        case .configuration_error_products_not_found:
            return "There's a problem with your configuration. None of the products registered in the RevenueCat " +
            "dashboard could be fetched from App Store Connect (or the StoreKit Configuration file " +
            "if one is being used). \nMore information: https://rev.cat/why-are-offerings-empty"

        case .configuration_error_no_products_for_offering:
            return "There are no products registered in the RevenueCat dashboard for your offerings. " +
            "If you don't want to use the offerings system, you can safely ignore this message. " +
            "To configure offerings and their products, follow the instructions in " +
            "https://rev.cat/how-to-configure-offerings.\nMore information: https://rev.cat/why-are-offerings-empty"

        case .offering_empty(let offeringIdentifier):
            return "There's a problem with your configuration. No packages could be found for offering with  " +
            "identifier \(offeringIdentifier). This could be due to Products not being configured correctly in the " +
            "RevenueCat dashboard, App Store Connect (or the StoreKit Configuration file " +
            "if one is being used). \nTo configure products, follow the instructions in " +
            "https://rev.cat/how-to-configure-offerings. \nMore information: https://rev.cat/why-are-offerings-empty"

        case let .product_details_empty_title(identifier):
            return "Empty Product titles are not supported. Found in product with identifier: \(identifier)"

        case let .unknown_package_type(package):
            return "Package '\(package.identifier)' in offering " +
            "'\(package.presentedOfferingContext.offeringIdentifier)' has an unknown duration." +
            "\nYou can reference this package by its identifier ('\(package.identifier)') directly." +
            "\nMore information: https://rev.cat/displaying-products"

        case let .custom_package_type(package):
            return "Package '\(package.identifier)' in offering " +
            "'\(package.presentedOfferingContext.offeringIdentifier)' has a custom duration." +
            "\nYou can reference this package by its identifier ('\(package.identifier)') directly." +
            "\nMore information: https://rev.cat/displaying-products"

        case let .overriding_package(old, new):
            return "Package: \(old) already exists, overwriting with: \(new)"
        }
    }

    var category: String { return "offering" }

}
