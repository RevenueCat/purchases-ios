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
        isLifetime: Bool = false,
        isTrial: Bool = false,
        isCancelled: Bool = false,
        isActive: Bool = true,
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
        storeTransactionIdentifier: String? = "store_tx_abc"
    ) -> PurchaseInformation {
        return PurchaseInformation(
            title: title,
            pricePaid: pricePaid,
            renewalPrice: renewalPrice,
            productIdentifier: productIdentifier,
            store: store,
            isLifetime: isLifetime,
            isTrial: isTrial,
            isCancelled: isCancelled,
            isActive: isActive,
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
            storeTransactionIdentifier: storeTransactionIdentifier
        )
    }

    static let monthlyRenewing = PurchaseInformation.mock(
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        store: .appStore,
        expirationDate: nil,
        renewalDate: Self.defaulRenewalDate
    )

    static let expired = PurchaseInformation.mock(
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id_expired",
        store: .appStore,
        isLifetime: false,
        isActive: false,
        expirationDate: nil,
        renewalDate: nil
    )

    static let lifetime = PurchaseInformation.mock(
        title: "Lifetime",
        pricePaid: .nonFree("$4.99"),
        productIdentifier: "product_id_lifetime",
        isLifetime: true,
        expirationDate: nil,
        renewalDate: nil
    )

    static let free = PurchaseInformation.mock(
        title: "Free",
        pricePaid: .free,
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id_free",
        isTrial: true,
        isActive: true,
        expirationDate: nil,
        renewalDate: nil
    )

    static func yearlyExpiring(
        title: String = "Product name",
        productIdentifier: String = "productIdentifier3",
        store: Store = .appStore,
        isCancelled: Bool = false,
        expirationDate: Date? = Self.defaultCustomerInfoRequestedDate,
        renewalDate: Date? = nil,
        introductoryDiscount: StoreProductDiscountType? = nil
    ) -> PurchaseInformation {
        PurchaseInformation.mock(
            title: title,
            pricePaid: .nonFree("$49.99"),
            renewalPrice: .nonFree("$49.99"),
            productIdentifier: productIdentifier,
            store: store,
            isLifetime: false,
            isCancelled: isCancelled,
            isActive: false,
            isSandbox: false,
            managementURL: URL(string: "https://www.revenuecat.com"),
            expirationDate: expirationDate,
            renewalDate: renewalDate,
            ownershipType: .purchased
        )
    }

    static let consumable = PurchaseInformation.mock(
        title: "Basic",
        pricePaid: .nonFree("$49.99"),
        renewalPrice: nil,
        productIdentifier: "product_id",
        store: .appStore,
        isLifetime: true,
        isActive: true,
        isSandbox: false,
        managementURL: URL(string: "https://www.revenuecat.com"),
        expirationDate: nil,
        renewalDate: nil
    )

}
