//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPurchases.swift
//
//  Created by Cesar de la Vega on 18/7/24.

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class CustomerCenterPurchases: CustomerCenterPurchasesType {

    var isSandbox: Bool {
        return Purchases.shared.isSandbox
    }

    var appUserID: String {
        return Purchases.shared.appUserID
    }

    var isConfigured: Bool {
        return Purchases.isConfigured
    }

    var storeFrontCountryCode: String? {
        return Purchases.shared.storeFrontCountryCode
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func customerInfo(
        fetchPolicy: CacheFetchPolicy
    ) async throws -> RevenueCat.CustomerInfo {
        try await Purchases.shared.customerInfo(fetchPolicy: fetchPolicy)
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
    }

    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer {
        try await Purchases.shared.promotionalOffer(forProductDiscount: discount,
                                                    product: product)
    }

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer?
    ) async throws -> PurchaseResultData {
        if let promotionalOffer = promotionalOffer {
            return try await Purchases.shared.purchase(
                product: product,
                promotionalOffer: promotionalOffer
            )
        } else {
            return try await Purchases.shared.purchase(product: product)
        }
    }

    func track(customerCenterEvent: any CustomerCenterEventType) {
        Purchases.shared.track(customerCenterEvent: customerCenterEvent)
    }

    func loadCustomerCenter() async throws -> CustomerCenterConfigData {
        try await Purchases.shared.loadCustomerCenter()
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }

    func syncPurchases() async throws -> CustomerInfo {
        try await Purchases.shared.syncPurchases()
    }

    func invalidateVirtualCurrenciesCache() {
        Purchases.shared.invalidateVirtualCurrenciesCache()
    }

    func virtualCurrencies() async throws -> VirtualCurrencies {
        return try await Purchases.shared.virtualCurrencies()
    }

    func offerings() async throws -> Offerings {
        return try await Purchases.shared.offerings()
    }

    func createTicket(customerEmail: String, ticketDescription: String) async throws -> Bool {
        return try await Purchases.shared.createTicket(
            customerEmail: customerEmail,
            ticketDescription: ticketDescription
        )
    }

    #if os(iOS) || os(visionOS)
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        try await Purchases.shared.beginRefundRequest(forProduct: productID)
    }
    #endif
}
