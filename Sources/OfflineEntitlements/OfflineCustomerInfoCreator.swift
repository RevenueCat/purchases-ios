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

/// A type that can create a `CustomerInfo` while offline.
protocol OfflineCustomerInfoCreatorType: Sendable {

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func create(for userID: String) async throws -> CustomerInfo

}

/// Holds the necessary dependencies to create a `CustomerInfo` while offline.
final class OfflineCustomerInfoCreator: OfflineCustomerInfoCreatorType {

    typealias Creator = @Sendable ([PurchasedSK2Product],
                                   ProductEntitlementMapping,
                                   String) -> CustomerInfo

    private let purchasedProductsFetcher: PurchasedProductsFetcherType
    private let productEntitlementMappingFetcher: ProductEntitlementMappingFetcher
    private let creator: Creator

    static func createPurchasedProductsFetcherIfAvailable() -> PurchasedProductsFetcherType? {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            return PurchasedProductsFetcher()
        } else {
            return nil
        }
    }

    static func createIfAvailable(
        with purchasedProductsFetcher: PurchasedProductsFetcherType?,
        productEntitlementMappingFetcher: ProductEntitlementMappingFetcher,
        observerMode: Bool
    ) -> OfflineCustomerInfoCreator? {
        guard let fetcher = purchasedProductsFetcher, !observerMode else {
            Logger.debug(Strings.offlineEntitlements.offline_entitlements_not_available)
            return nil
        }

        return .init(purchasedProductsFetcher: fetcher,
                     productEntitlementMappingFetcher: productEntitlementMappingFetcher)
    }

    convenience init(purchasedProductsFetcher: PurchasedProductsFetcherType,
                     productEntitlementMappingFetcher: ProductEntitlementMappingFetcher) {
        self.init(
            purchasedProductsFetcher: purchasedProductsFetcher,
            productEntitlementMappingFetcher: productEntitlementMappingFetcher,
            creator: { products, mapping, userID in
                CustomerInfo(from: products, mapping: mapping, userID: userID)
            }
        )
    }

    init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMappingFetcher: ProductEntitlementMappingFetcher,
        creator: @escaping Creator
    ) {
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.productEntitlementMappingFetcher = productEntitlementMappingFetcher
        self.creator = creator
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func create(for userID: String) async throws -> CustomerInfo {
        Logger.info(Strings.offlineEntitlements.computing_offline_customer_info)

        guard let mapping = self.productEntitlementMappingFetcher.productEntitlementMapping else {
            Logger.warn(Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping)
            throw Error.noEntitlementMappingAvailable
        }

        let products = try await self.purchasedProductsFetcher.fetchPurchasedProducts()

        let offlineCustomerInfo = creator(products, mapping, userID)

        Logger.info(Strings.offlineEntitlements.computed_offline_customer_info(
            products, offlineCustomerInfo.entitlements
        ))
        Logger.debug(Strings.offlineEntitlements.computed_offline_customer_info_details(
            products, offlineCustomerInfo.entitlements
        ))

        return offlineCustomerInfo
    }

}

extension OfflineCustomerInfoCreator: Sendable {}

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
