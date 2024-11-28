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

    var isSandbox: Bool = false

    var customerInfoCallCount = 0
    var customerInfoResult: Result<CustomerInfo, Error> = .failure(NSError(domain: "", code: -1))
    func customerInfo() async throws -> CustomerInfo {
        customerInfoCallCount += 1
        return try customerInfoResult.get()
    }

    var productsCallCount = 0
    var productsResult: [StoreProduct] = []
    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        productsCallCount += 1
        return productsResult
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
    var trackedEvents: [CustomerCenterEvent] = []
    func track(customerCenterEvent: CustomerCenterEvent) {
        trackCallCount += 1
        trackedEvents.append(customerCenterEvent)
    }
}
