//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductType.swift
//
//  Created by Nacho Soto on 2/15/22.

import StoreKit

extension StoreProduct {

    /// The category of a product, whether a subscription or a one-time purchase.
    ///
    /// ### Related Symbols
    /// - ``StoreProduct/ProductType-swift.enum``
    @objc(RCStoreProductCategory)
    public enum ProductCategory: Int {

        /// A non-renewable or auto-renewable subscription.
        case subscription

        /// A consumable or non-consumable in-app purchase.
        case nonSubscription

    }

    /// The type of product, equivalent to StoreKit's `Product.ProductType`.
    ///
    /// ### Related Symbols
    /// - ``StoreProduct/ProductCategory-swift.enum``
    @objc(RCStoreProductType)
    public enum ProductType: Int {

        /// A consumable in-app purchase.
        case consumable

        /// A non-consumable in-app purchase.
        case nonConsumable

        /// A non-renewing subscription.
        case nonRenewableSubscription

        /// An auto-renewable subscription.
        case autoRenewableSubscription

    }

}

extension StoreProduct.ProductType {

    var productCategory: StoreProduct.ProductCategory {
        switch self {
        case .consumable: return .nonSubscription
        case .nonConsumable: return .nonSubscription
        case .nonRenewableSubscription: return .subscription
        case .autoRenewableSubscription: return .subscription
        }
    }

    /// Used as a placeholder when the type of product cannot be determined.
    /// This value is considered undefined behavior.
    static let defaultType: Self = .nonConsumable

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension StoreProduct.ProductType {

    init(_ type: SK2Product.ProductType) {
        switch type {
        case .consumable: self = .consumable
        case .nonConsumable: self = .nonConsumable
        case .nonRenewable: self = .nonRenewableSubscription
        case .autoRenewable: self = .autoRenewableSubscription

        default:
            Logger.warn(Strings.storeKit.sk2_unknown_product_type(String(describing: type)))

            self = .defaultType
        }
    }

}

extension StoreProduct.ProductCategory: Sendable {}
extension StoreProduct.ProductType: Sendable {}
