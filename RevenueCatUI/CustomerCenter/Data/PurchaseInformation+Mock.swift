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

// swiftlint:disable force_unwrapping
extension PurchaseInformation {
    static let defaulRenewalDate = Date(timeIntervalSince1970: 1747876800)
    static let defaultLatestPurchaseDate = Date(timeIntervalSince1970: 1747862400)
    static let defaultCustomerInfoRequestedDate = Date(timeIntervalSince1970: 1747862400)

    static let monthlyRenewing = PurchaseInformation(
        title: "Basic",
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id5",
        store: .appStore,
        isLifetime: false,
        isTrial: false,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil,
        ownershipType: .purchased
    )

    static let expired = PurchaseInformation(
        title: "Basic",
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id5",
        store: .appStore,
        isLifetime: false,
        isTrial: false,
        isCancelled: false,
        isActive: false,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )

    static let lifetime = PurchaseInformation(
        title: "Lifetime",
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id5",
        store: .appStore,
        isLifetime: true,
        isTrial: false,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil,
        ownershipType: .purchased
    )

    static let free = PurchaseInformation(
        title: "Basic",
        pricePaid: .free,
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id2",
        store: .appStore,
        isLifetime: false,
        isTrial: true,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil,
        ownershipType: .purchased
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
        PurchaseInformation(
            title: title,
            pricePaid: .nonFree("$49.99"),
            renewalPrice: .nonFree("$49.99"),
            productIdentifier: productIdentifier,
            store: store,
            isLifetime: false,
            isTrial: false,
            isCancelled: false,
            isActive: expirationDate == nil,
            isSandbox: false,
            latestPurchaseDate: Self.defaultLatestPurchaseDate,
            originalPurchaseDate: nil,
            customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
            managementURL: URL(string: "https://www.revenuecat.com")!,
            expirationDate: expirationDate,
            renewalDate: renewalDate,
            ownershipType: .purchased
        )
    }

    static let consumable: PurchaseInformation = PurchaseInformation(
        title: "Basic",
        pricePaid: .nonFree("$49.99"),
        renewalPrice: nil,
        productIdentifier: "product_id",
        store: .appStore,
        isLifetime: true,
        isTrial: false,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )

    static let subscriptionInformationMonthlyRenewing = PurchaseInformation(
        title: "Basic",
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id",
        store: .appStore,
        isLifetime: false,
        isTrial: false,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )

    static let subscriptionInformationFree = PurchaseInformation(
        title: "Basic",
        pricePaid: .free,
        renewalPrice: .nonFree("$4.99"),
        productIdentifier: "product_id",
        store: .appStore,
        isLifetime: false,
        isTrial: false,
        isCancelled: false,
        isActive: true,
        isSandbox: false,
        latestPurchaseDate: Self.defaultLatestPurchaseDate,
        originalPurchaseDate: nil,
        customerInfoRequestedDate: Self.defaultCustomerInfoRequestedDate,
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil,
        ownershipType: .purchased
    )

    static func mockLifetime(
        customerInfoRequestedDate: Date = Self.defaultCustomerInfoRequestedDate,
        store: Store = .appStore
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            pricePaid: .nonFree(""),
            renewalPrice: nil,
            productIdentifier: "",
            store: store,
            isLifetime: true,
            isTrial: false,
            isCancelled: false,
            isActive: true,
            isSandbox: false,
            latestPurchaseDate: Self.defaultLatestPurchaseDate,
            originalPurchaseDate: nil,
            customerInfoRequestedDate: customerInfoRequestedDate,
            managementURL: URL(string: "https://www.revenuecat.com")!
        )
    }

    static func mockNonLifetime(
        store: Store = .appStore,
        pricePaid: PurchaseInformation.PricePaid = .nonFree("5"),
        renewalPrice: PurchaseInformation.RenewalPrice = .nonFree("5"),
        isTrial: Bool = false,
        isCancelled: Bool = false,
        latestPurchaseDate: Date = Self.defaultLatestPurchaseDate,
        customerInfoRequestedDate: Date = Self.defaultCustomerInfoRequestedDate,
        managementURL: URL? = URL(string: "https://www.revenuecat.com")!
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: "",
            pricePaid: pricePaid,
            renewalPrice: renewalPrice,
            productIdentifier: "",
            store: store,
            isLifetime: false,
            isTrial: isTrial,
            isCancelled: isCancelled,
            isActive: true,
            isSandbox: false,
            latestPurchaseDate: latestPurchaseDate,
            originalPurchaseDate: nil,
            customerInfoRequestedDate: customerInfoRequestedDate,
            managementURL: managementURL
        )
    }
}
