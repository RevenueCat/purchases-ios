//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreProduct.swift
//
//  Created by Nacho Soto on 6/23/23.

import Foundation

/// A type that contains the necessary data to create a ``StoreProduct``.
/// This can be used to create mock data for tests or SwiftUI previews.
///
/// Example:
/// ```swift
/// let product = TestStoreProduct(
///     localizedTitle: "PRO monthly",
///     price: 3.99,
///     localizedPriceString: "$3.99",
///     productIdentifier: "com.revenuecat.product",
///     productType: .autoRenewableSubscription,
///     localizedDescription: "Description",
///     subscriptionGroupIdentifier: "group",
///     subscriptionPeriod: .init(value: 1, unit: .month)
/// )
///
/// let offering = Offering(
///     identifier: "offering",
///     serverDescription: "Main offering",
///     metadata: [:],
///     availablePackages: [
///         .init(
///             identifier: "monthly",
///             packageType: .monthly,
///             storeProduct: product.toStoreProduct(),
///             offeringIdentifier: offering
///         ),
///     ]
/// )
/// ```
public struct TestStoreProduct {

    // Note: this class inherits its docs from `StoreProductType`
    // swiftlint:disable missing_docs

    public var localizedTitle: String
    public var price: Decimal
    public var localizedPriceString: String
    public var localizedPricePerDay: String?
    public var localizedPricePerWeek: String?
    public var localizedPricePerMonth: String?
    public var localizedPricePerYear: String?
    public var productIdentifier: String
    public var productType: StoreProduct.ProductType
    public var localizedDescription: String
    public var subscriptionGroupIdentifier: String?
    public var subscriptionPeriod: SubscriptionPeriod?
    public var isFamilyShareable: Bool
    public var introductoryDiscount: StoreProductDiscount?
    public var discounts: [StoreProductDiscount]
    public var locale: Locale

    public init(
        localizedTitle: String,
        price: Decimal,
        localizedPriceString: String,
        productIdentifier: String,
        productType: StoreProduct.ProductType,
        localizedDescription: String,
        subscriptionGroupIdentifier: String? = nil,
        subscriptionPeriod: SubscriptionPeriod? = nil,
        isFamilyShareable: Bool = false,
        introductoryDiscount: TestStoreProductDiscount? = nil,
        discounts: [TestStoreProductDiscount] = [],
        locale: Locale = .current
    ) {
        self.localizedTitle = localizedTitle
        self.price = price
        self.localizedPriceString = localizedPriceString
        self.productIdentifier = productIdentifier
        self.productType = productType
        self.localizedDescription = localizedDescription
        self.subscriptionGroupIdentifier = subscriptionGroupIdentifier
        self.subscriptionPeriod = subscriptionPeriod
        self.isFamilyShareable = isFamilyShareable
        self.introductoryDiscount = introductoryDiscount?.toStoreProductDiscount()
        self.discounts = discounts.map { $0.toStoreProductDiscount() }
        self.locale = locale
    }

    // swiftlint:enable missing_docs

    private let priceFormatterProvider: PriceFormatterProvider = .init()

}

// Ensure consistency with the internal type
extension TestStoreProduct: StoreProductType {

    internal var productCategory: StoreProduct.ProductCategory { return self.productType.productCategory }

    internal var currencyCode: String? {
        return self.locale.rc_currencyCode
    }

    internal var priceFormatter: NumberFormatter? {
        return self.currencyCode.map {
            self.priceFormatterProvider.priceFormatterForSK2(withCurrencyCode: $0, locale: self.locale)
        }
    }

}

extension TestStoreProduct {

    /// Convert it into a ``StoreProduct``.
    public func toStoreProduct() -> StoreProduct {
        return .from(product: self)
    }

}
