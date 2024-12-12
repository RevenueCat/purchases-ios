//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPurchaseType.swift
//
//  Created by Cesar de la Vega on 18/7/24.

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol CustomerCenterPurchasesType: Sendable {

    var isSandbox: Bool { get }

    @Sendable
    func customerInfo(
        fetchPolicy: CacheFetchPolicy
    ) async throws -> CustomerInfo

    @Sendable
    func products(_ productIdentifiers: [String]) async -> [StoreProduct]

    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer
    ) async throws -> PurchaseResultData

    func track(customerCenterEvent: any CustomerCenterEventType)

    func loadCustomerCenter() async throws -> CustomerCenterConfigData

    func restorePurchases() async throws -> CustomerInfo

}
