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
    static let monthlyRenewing = PurchaseInformation(
        title: "Basic",
        durationTitle: "Monthly",
        pricePaid: .nonFree("$4.99"),
        renewalPrice: .nonFree("$4.99"),
        expirationOrRenewal: .init(label: .nextBillingDate, date: .date("June 1st, 2024")),
        productIdentifier: "product_id5",
        store: .appStore,
        isLifetime: false,
        isTrial: false,
        isCancelled: false,
        latestPurchaseDate: nil,
        customerInfoRequestedDate: Date(),
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )

    static let free = PurchaseInformation(
        title: "Basic",
        durationTitle: "Monthly",
        pricePaid: .free,
        renewalPrice: .nonFree("$4.99"),
        expirationOrRenewal: .init(label: .nextBillingDate,
                                   date: .date("June 1st, 2024")),
        productIdentifier: "product_id2",
        store: .appStore,
        isLifetime: false,
        isTrial: true,
        isCancelled: false,
        latestPurchaseDate: nil,
        customerInfoRequestedDate: Date(),
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )

    static func yearlyExpiring(
        title: String = "Product name",
        productIdentifier: String = "productIdentifier3",
        store: Store = .appStore,
        isCancelled: Bool = false,
        expirationDate: Date = Date(),
        renewalDate: Date? = nil,
        introductoryDiscount: StoreProductDiscountType? = nil
    ) -> PurchaseInformation {
        PurchaseInformation(
            title: title,
            durationTitle: "Yearly",
            pricePaid: .nonFree("$49.99"),
            renewalPrice: .nonFree("$49.99"),
            expirationOrRenewal: .init(label: .expires, date: .date("June 1st, 2024")),
            productIdentifier: productIdentifier,
            store: store,
            isLifetime: false,
            isTrial: false,
            isCancelled: false,
            latestPurchaseDate: nil,
            customerInfoRequestedDate: Date(),
            managementURL: URL(string: "https://www.revenuecat.com")!,
            expirationDate: expirationDate,
            renewalDate: renewalDate
        )
    }

    static let consumable: PurchaseInformation = PurchaseInformation(
        title: "Basic",
        durationTitle: nil,
        pricePaid: .nonFree("$49.99"),
        renewalPrice: nil,
        expirationOrRenewal: nil,
        productIdentifier: "product_id",
        store: .appStore,
        isLifetime: true,
        isTrial: false,
        isCancelled: false,
        latestPurchaseDate: Date(),
        customerInfoRequestedDate: Date(),
        managementURL: URL(string: "https://www.revenuecat.com")!,
        expirationDate: nil,
        renewalDate: nil
    )
}
