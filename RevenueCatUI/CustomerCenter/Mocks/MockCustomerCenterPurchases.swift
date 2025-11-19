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
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class MockCustomerCenterPurchases: @unchecked Sendable, CustomerCenterPurchasesType {

    let appUserID: String = "$RC_MOCK_APP_USER_ID"
    let isConfigured: Bool = true
    let storeFrontCountryCode: String? = "ESP"

    var customerInfo: CustomerInfo
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
        beginRefundShouldFail: Bool = false,
        customerCenterConfigData: CustomerCenterConfigData = CustomerCenterConfigData.mock(
            lastPublishedAppVersion: "2.0.0"
        )
    ) {
        self.customerInfo = customerInfo
        self.customerInfoError = customerInfoError
        self.products = Dictionary(uniqueKeysWithValues: products.map({ product in
            (product.productIdentifier, product)
        }))
        self.showManageSubscriptionsError = showManageSubscriptionsError
        self.beginRefundShouldFail = beginRefundShouldFail
        self.loadCustomerCenterResult = .success(customerCenterConfigData)
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        if let customerInfoError {
            throw customerInfoError
        }
        return customerInfo
    }

    var customerInfoFetchPolicy: CacheFetchPolicy?
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> RevenueCat.CustomerInfo {
        customerInfoFetchPolicy = fetchPolicy

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
                  promotionalOffer: PromotionalOffer?) async throws -> PurchaseResultData {
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

    var loadCustomerCenterCallCount = 0
    var loadCustomerCenterResult: Result<CustomerCenterConfigData, Error> = .failure(NSError(domain: "", code: -1))
    func loadCustomerCenter() async throws -> CustomerCenterConfigData {
        loadCustomerCenterCallCount += 1
        return try loadCustomerCenterResult.get()
    }

    var restorePurchasesCallCount = 0
    var restorePurchasesResult: Result<CustomerInfo, Error> = .failure(NSError(domain: "", code: -1))
    func restorePurchases() async throws -> CustomerInfo {
        restorePurchasesCallCount += 1
        return try restorePurchasesResult.get()
    }

    var invalidateVirtualCurrenciesCacheCallCount = 0
    func invalidateVirtualCurrenciesCache() {
        invalidateVirtualCurrenciesCacheCallCount += 1
    }

    var virtualCurrenciesCallCount = 0
    var virtualCurrenciesResult: Result<VirtualCurrencies, Error>?
    func virtualCurrencies() async throws -> VirtualCurrencies {
        virtualCurrenciesCallCount += 1
        return try virtualCurrenciesResult?.get() ?? VirtualCurrenciesFixtures.noVirtualCurrencies
    }

    func showManageSubscriptions() async throws {
        if let showManageSubscriptionsError {
            throw showManageSubscriptionsError
        }
    }

    func beginRefundRequest(forProduct productID: String) async throws -> RevenueCat.RefundRequestStatus {
        if beginRefundShouldFail {
            return .error
        }
        return .success
    }

    var syncPurchasesCount = 0
    var syncPurchasesResult: CustomerInfo = CustomerInfoFixtures.customerInfoWithLifetimePromotional
    func syncPurchases() async throws -> CustomerInfo {
        syncPurchasesCount += 1
        return syncPurchasesResult
    }

    var offeringsError: Error = NSError(domain: "", code: -1)
    func offerings() async throws -> Offerings {
        throw offeringsError
    }

    var createTicketResult: Result<Bool, Error> = .success(true)
    func createTicket(customerEmail: String, ticketDescription: String) async throws -> Bool {
        return try createTicketResult.get()
    }
}
