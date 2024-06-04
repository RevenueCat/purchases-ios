//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineEntitlementsStrings.swift
//
//  Created by Nacho Soto on 3/22/23.

import Foundation
import StoreKit

// swiftlint:disable identifier_name

enum OfflineEntitlementsStrings {

    case offline_entitlements_not_available

    case product_entitlement_mapping_stale_updating
    case product_entitlement_mapping_updated_from_network
    case product_entitlement_mapping_unavailable
    case product_entitlement_mapping_fetching_error(BackendError)
    case found_unverified_transactions_in_sk2(transactionID: UInt64, Error)

    case computing_offline_customer_info_with_no_entitlement_mapping
    case computing_offline_customer_info_for_consumable_product
    case computing_offline_customer_info
    case computing_offline_customer_info_failed(Error)
    case computed_offline_customer_info([PurchasedSK2Product], EntitlementInfos)
    case computed_offline_customer_info_details([PurchasedSK2Product], EntitlementInfos)

    case purchased_products_fetching
    case purchased_products_fetched(count: Int)
    case purchased_products_fetching_too_slow
    case purchased_products_returning_cache(count: Int)
    case purchased_products_invalidating_cache

}

extension OfflineEntitlementsStrings: LogMessage {

    var description: String {
        switch self {
        case .offline_entitlements_not_available:
            return "Offline entitlements not available."

        case .product_entitlement_mapping_stale_updating:
            return "ProductEntitlementMapping cache is stale, updating from network."

        case .product_entitlement_mapping_updated_from_network:
            return "ProductEntitlementMapping cache updated from network."

        case .product_entitlement_mapping_unavailable:
            return "Offline entitlements aren't available, won't fetch ProductEntitlementMapping."

        case let .product_entitlement_mapping_fetching_error(error):
            return "Failed updating ProductEntitlementMapping from network: \(error.localizedDescription)"

        case let .found_unverified_transactions_in_sk2(transactionID, error):
            return """
                Found an unverified transaction. It will be ignored and will not be a part of CustomerInfo.
                Details:
                Error: \(error.localizedDescription)
                Transaction ID: \(transactionID)
            """

        case .computing_offline_customer_info_with_no_entitlement_mapping:
            return "Unable to compute offline CustomerInfo with no product entitlement mapping."

        case .computing_offline_customer_info_for_consumable_product:
            return "Unable to compute offline CustomerInfo when purchasing consumable products."

        case .computing_offline_customer_info:
            return "Encountered a server error. Will attempt to compute an offline CustomerInfo from local purchases."

        case let .computing_offline_customer_info_failed(error):
            return "Error computing offline CustomerInfo. Will return original error.\n" +
            "Creation error: \(error.localizedDescription)"

        case let .computed_offline_customer_info(products, entitlements):
            return "Computed offline CustomerInfo from \(products.count) products " +
            "with \(entitlements.active.count) active entitlements."

        case let .computed_offline_customer_info_details(products, entitlements):
            let productIDs = products
                .lazy
                .map(\.productIdentifier)
                .joined(separator: ", ")
            let entitlements = entitlements
                .active
                .values
                .lazy
                .map(\.identifier)
                .joined(separator: ", ")

            return "Purchased products: [\(productIDs)]. Active entitlements: [\(entitlements)]."

        case .purchased_products_fetching:
            return "PurchasedProductsFetcher: fetching products from StoreKit"

        case let .purchased_products_fetched(count):
            return "PurchasedProductsFetcher: fetched \(count) products from StoreKit"

        case .purchased_products_fetching_too_slow:
            return "PurchasedProductsFetcher: fetching products took too long"

        case let .purchased_products_returning_cache(count):
            return "PurchasedProductsFetcher: returning \(count) cached products"

        case .purchased_products_invalidating_cache:
            return "PurchasedProductsFetcher: invalidating cache"
        }
    }

    var category: String { return "offline_entitlements" }

}
