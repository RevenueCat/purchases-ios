//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformation+Mock.swift
//
//  Created by Facundo Menzella on 12/5/25.

import Foundation
@_spi(Internal) import RevenueCat

extension PurchaseInformation {

    static let defaulRenewalDate = Date(timeIntervalSince1970: 1747876800)
    static let defaultOriginalPurchaseDate = Date(timeIntervalSince1970: 1747876800)
    static let defaultLatestPurchaseDate = Date(timeIntervalSince1970: 1747862400)
    static let defaultExpirationDate = Date(timeIntervalSince1970: 1747876800)
    static let defaultCustomerInfoRequestedDate = Date(timeIntervalSince1970: 1747862400)

    static func mock(
        title: String = "Pro Subscription",
        pricePaid: PricePaid = .nonFree("$9.99"),
        renewalPrice: RenewalPrice? = .nonFree("$9.99"),
        productIdentifier: String = "com.revenuecat.pro",
        store: Store = .appStore,
        isSubscription: Bool = false,
        productType: StoreProduct.ProductType? = nil,
        isTrial: Bool = false,
        isCancelled: Bool = false,
        isExpired: Bool = false,
        isSandbox: Bool = true,
        latestPurchaseDate: Date = Self.defaultLatestPurchaseDate,
        originalPurchaseDate: Date? = Self.defaultOriginalPurchaseDate,
        customerInfoRequestedDate: Date = Self.defaultCustomerInfoRequestedDate,
        managementURL: URL? = URL(string: "https://www.revenuecat.com"),
        expirationDate: Date? = Self.defaultExpirationDate,
        renewalDate: Date? = Self.defaulRenewalDate,
        periodType: PeriodType = .normal,
        ownershipType: PurchaseOwnershipType? = .purchased,
        subscriptionGroupID: String? = "12345678",
        unsubscribeDetectedAt: Date? = nil,
        billingIssuesDetectedAt: Date? = nil,
        gracePeriodExpiresDate: Date? = nil,
        refundedAtDate: Date? = nil,
        transactionIdentifier: String? = "rc_tx_123",
        storeTransactionIdentifier: String? = "store_tx_abc",
        isLifetime: Bool = false
    ) -> PurchaseInformation {
        return PurchaseInformation(
            title: title,
            pricePaid: pricePaid,
            renewalPrice: renewalPrice,
            productIdentifier: productIdentifier,
            store: store,
            isSubscription: isSubscription,
            productType: productType,
            isTrial: isTrial,
            isCancelled: isCancelled,
            isExpired: isExpired,
            isSandbox: isSandbox,
            latestPurchaseDate: latestPurchaseDate,
            originalPurchaseDate: originalPurchaseDate,
            customerInfoRequestedDate: customerInfoRequestedDate,
            managementURL: managementURL,
            expirationDate: expirationDate,
            renewalDate: renewalDate,
            periodType: periodType,
            ownershipType: ownershipType,
            subscriptionGroupID: subscriptionGroupID,
            unsubscribeDetectedAt: unsubscribeDetectedAt,
            billingIssuesDetectedAt: billingIssuesDetectedAt,
            gracePeriodExpiresDate: gracePeriodExpiresDate,
            refundedAtDate: refundedAtDate,
            transactionIdentifier: transactionIdentifier,
            storeTransactionIdentifier: storeTransactionIdentifier,
            isLifetime: isLifetime
        )
    }

    static let subscription = PurchaseInformation.mock(
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        store: .appStore,
        isSubscription: true,
        productType: .autoRenewableSubscription,
        isCancelled: false,
        expirationDate: nil,
        renewalDate: Self.defaulRenewalDate
    )

    static let expired = PurchaseInformation.mock(
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id_expired",
        store: .appStore,
        isSubscription: true,
        productType: .autoRenewableSubscription,
        isExpired: true,
        expirationDate: Self.defaultExpirationDate,
        renewalDate: nil
    )

    static let lifetime = PurchaseInformation.mock(
        title: "Lifetime",
        pricePaid: .nonFree("$4.99"),
        productIdentifier: "product_id_lifetime",
        isSubscription: true,
        productType: .nonConsumable,
        expirationDate: nil,
        renewalDate: nil,
        isLifetime: true
    )

    static let free = PurchaseInformation.mock(
        title: "Free",
        pricePaid: .free,
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id_free",
        isTrial: true,
        isExpired: false,
        expirationDate: nil,
        renewalDate: Self.defaultExpirationDate
    )

    static let consumable = PurchaseInformation.mock(
        title: "Basic",
        pricePaid: .nonFree("$49.99"),
        renewalPrice: nil,
        productIdentifier: "product_id",
        store: .appStore,
        isSubscription: false,
        productType: .consumable,
        isExpired: false,
        isSandbox: false,
        managementURL: URL(string: "https://www.revenuecat.com"),
        expirationDate: nil,
        renewalDate: nil
    )

}
