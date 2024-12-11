//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockCustomerCenterPurchases.swift
//
//  Created by Cesar de la Vega on 28/11/24.

import Foundation
import RevenueCat
@testable import RevenueCatUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class MockCustomerCenterPurchases: @unchecked Sendable, CustomerCenterPurchasesType {

    let customerInfo: CustomerInfo
    let customerInfoError: Error?
    // StoreProducts keyed by productIdentifier.
    let products: [String: RevenueCat.StoreProduct]
    let showManageSubscriptionsError: Error?
    let beginRefundShouldFail: Bool

    var isSandbox: Bool = false

    init(
        customerInfo: CustomerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions,
        customerInfoError: Error? = nil,
        products: [RevenueCat.StoreProduct] =
        [PurchaseInformationFixtures.product(id: "com.revenuecat.product",
                                             title: "title",
                                             duration: .month,
                                             price: 2.99)],
        showManageSubscriptionsError: Error? = nil,
        beginRefundShouldFail: Bool = false
    ) {
        self.customerInfo = customerInfo
        self.customerInfoError = customerInfoError
        self.products = Dictionary(uniqueKeysWithValues: products.map({ product in
            (product.productIdentifier, product)
        }))
        self.showManageSubscriptionsError = showManageSubscriptionsError
        self.beginRefundShouldFail = beginRefundShouldFail
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        if let customerInfoError {
            throw customerInfoError
        }
        return customerInfo
    }

    func products(_ productIdentifiers: [String]) async -> [RevenueCat.StoreProduct] {
        return productIdentifiers.compactMap { productIdentifier in
            products[productIdentifier]
        }
    }

    var promotionalOfferCallCount = 0
    var promotionalOfferResult: Result<PromotionalOffer, Error> = .failure(NSError(domain: "", code: -1))
    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer {
        promotionalOfferCallCount += 1
        return try promotionalOfferResult.get()
    }

    var purchaseCallCount = 0
    var purchaseResult: Result<PurchaseResultData, Error> = .failure(NSError(domain: "", code: -1))
    func purchase(product: StoreProduct,
                  promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        purchaseCallCount += 1
        return try purchaseResult.get()
    }

    var trackCallCount = 0
    var trackError: Error?
    var trackedEvents: [CustomerCenterEventType] = []
    func track(customerCenterEvent: any CustomerCenterEventType) {
        trackCallCount += 1
        trackedEvents.append(customerCenterEvent)
    }
}
