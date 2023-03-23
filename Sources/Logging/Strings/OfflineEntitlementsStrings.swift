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

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
enum OfflineEntitlementsStrings {

    case product_entitlement_mapping_stale_updating
    case product_entitlement_mapping_updated_from_network
    case product_entitlement_mapping_fetching_error(BackendError)
    case found_unverified_transactions_in_sk2(StoreKit.Transaction, Error)

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension OfflineEntitlementsStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .product_entitlement_mapping_stale_updating:
            return "ProductEntitlementMapping cache is stale, updating from network."

        case .product_entitlement_mapping_updated_from_network:
            return "ProductEntitlementMapping cache updated from network."

        case let .product_entitlement_mapping_fetching_error(error):
            return "Failed updating ProductEntitlementMapping from network: \(error.localizedDescription)"

        case let .found_unverified_transactions_in_sk2(transaction, error):
            return """
                Found an unverified transaction. It will be ignored and will not be a part of CustomerInfo.
                Details:
                Error: \(error.localizedDescription)
                Transaction: \(transaction.debugDescription)
            """

        }
    }

}
