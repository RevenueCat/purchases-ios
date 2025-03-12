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
class OfflineCustomerInfoCreator {

    typealias Creator = @Sendable ([PurchasedSK2Product],
                                   ProductEntitlementMapping,
                                   String) -> CustomerInfo

    private let purchasedProductsFetcher: PurchasedProductsFetcherType
    private let productEntitlementMappingFetcher: ProductEntitlementMappingFetcher
    private let tracker: DiagnosticsTrackerType?
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
        tracker: DiagnosticsTrackerType?,
        observerMode: Bool
    ) -> OfflineCustomerInfoCreator? {
        guard let fetcher = purchasedProductsFetcher, !observerMode else {
            Logger.debug(Strings.offlineEntitlements.offline_entitlements_not_available)
            return nil
        }

        return .init(purchasedProductsFetcher: fetcher,
                     productEntitlementMappingFetcher: productEntitlementMappingFetcher,
                     tracker: tracker)
    }

    convenience init(purchasedProductsFetcher: PurchasedProductsFetcherType,
                     productEntitlementMappingFetcher: ProductEntitlementMappingFetcher,
                     tracker: DiagnosticsTrackerType?) {
        self.init(
            purchasedProductsFetcher: purchasedProductsFetcher,
            productEntitlementMappingFetcher: productEntitlementMappingFetcher,
            tracker: tracker,
            creator: { products, mapping, userID in
                CustomerInfo(from: products, mapping: mapping, userID: userID)
            }
        )
    }

    init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMappingFetcher: ProductEntitlementMappingFetcher,
        tracker: DiagnosticsTrackerType?,
        creator: @escaping Creator
    ) {
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.productEntitlementMappingFetcher = productEntitlementMappingFetcher
        self.tracker = tracker
        self.creator = creator
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func create(for userID: String) async throws -> CustomerInfo {
        do {
            Logger.info(Strings.offlineEntitlements.computing_offline_customer_info)

            guard let mapping = self.productEntitlementMappingFetcher.productEntitlementMapping else {
                Logger.warn(Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping)
                throw Error.noEntitlementMappingAvailable
            }

            let products = try await self.purchasedProductsFetcher.fetchPurchasedProducts()

            let offlineCustomerInfo = creator(products, mapping, userID)

            self.tracker?.trackEnteredOfflineEntitlementsMode()

            Logger.info(Strings.offlineEntitlements.computed_offline_customer_info(
                products, offlineCustomerInfo.entitlements
            ))
            Logger.debug(Strings.offlineEntitlements.computed_offline_customer_info_details(
                products, offlineCustomerInfo.entitlements
            ))

            return offlineCustomerInfo
        } catch {
            let reason: DiagnosticsEvent.OfflineEntitlementsModeErrorReason
            let errorMessage: String
            switch error {
            case let productsFetcherError as PurchasedProductsFetcher.Error:
                switch productsFetcherError {
                case .foundConsumablePurchase:
                    reason = .oneTimePurchaseFound
                    errorMessage = productsFetcherError.errorUserInfo[NSLocalizedDescriptionKey] as? String ?? ""
                }
            case let offlineCustomerInfoCreatorError as OfflineCustomerInfoCreator.Error:
                switch offlineCustomerInfoCreatorError {
                case .noEntitlementMappingAvailable:
                    reason = .noEntitlementMappingAvailable
                    errorMessage = offlineCustomerInfoCreatorError.description
                }
            default:
                reason = .unknown
                errorMessage = error.localizedDescription
            }

            self.tracker?.trackErrorEnteringOfflineEntitlementsMode(reason: reason, errorMessage: errorMessage)
            throw error
        }
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
