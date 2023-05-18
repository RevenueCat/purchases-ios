//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineCustomerInfoCreator.swift
//
//  Created by Nacho Soto on 5/18/23.

import Foundation

/// Holds the necessary dependencies to create a `CustomerInfo` while offline.
final class OfflineCustomerInfoCreator {

    typealias Creator = @Sendable ([PurchasedSK2Product],
                                   ProductEntitlementMapping,
                                   String) -> CustomerInfo

    private let purchasedProductsFetcher: PurchasedProductsFetcherType
    private let productEntitlementMapping: ProductEntitlementMapping?
    private let creator: Creator

    convenience init(purchasedProductsFetcher: PurchasedProductsFetcherType,
                     productEntitlementMapping: ProductEntitlementMapping?) {
        self.init(
            purchasedProductsFetcher: purchasedProductsFetcher,
            productEntitlementMapping: productEntitlementMapping,
            creator: { products, mapping, userID in
                CustomerInfo(from: products, mapping: mapping, userID: userID)
            }
        )
    }

    init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMapping: ProductEntitlementMapping?,
        creator: @escaping Creator
    ) {
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.productEntitlementMapping = productEntitlementMapping
        self.creator = creator
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func create(for userID: String) async throws -> CustomerInfo {
        Logger.info(Strings.offlineEntitlements.computing_offline_customer_info)

        guard let mapping = self.productEntitlementMapping, !mapping.entitlementsByProduct.isEmpty else {
            Logger.warn(Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping)
            throw Error.noEntitlementMappingAvailable
        }

        let products = try await self.purchasedProductsFetcher.fetchPurchasedProducts()

        let offlineCustomerInfo = creator(products, mapping, userID)

        Logger.info(Strings.offlineEntitlements.computed_offline_customer_info(offlineCustomerInfo.entitlements))

        return offlineCustomerInfo
    }

}

// MARK: - Errors

private extension OfflineCustomerInfoCreator {

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    enum Error: Swift.Error {

        case noEntitlementMappingAvailable

    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension OfflineCustomerInfoCreator.Error: DescribableError, CustomNSError {

    var description: String {
        switch self {
        case .noEntitlementMappingAvailable:
            return Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping.description
        }
    }

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

}
