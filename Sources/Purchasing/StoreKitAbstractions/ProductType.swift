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

        /// A subscription bundle.
        case subscriptionBundle

        /// A subscription suite.
        case subscriptionSuite

    }

}

extension StoreProduct.ProductType {

    var productCategory: StoreProduct.ProductCategory {
        switch self {
        case .consumable: return .nonSubscription
        case .nonConsumable: return .nonSubscription
        case .nonRenewableSubscription: return .subscription
        case .autoRenewableSubscription: return .subscription
        case .subscriptionBundle: return .subscription
        case .subscriptionSuite: return .subscription
        }
    }

    /// Used as a placeholder when the type of product cannot be determined.
    /// This value is considered undefined behavior.
    static let defaultType: Self = .nonConsumable

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension StoreProduct.ProductType {

    init(_ type: SK2Product.ProductType) {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *) {
            switch type {
            case .consumable: self = .consumable
            case .nonConsumable: self = .nonConsumable
            case .nonRenewable: self = .nonRenewableSubscription
            case .autoRenewable: self = .autoRenewableSubscription
            case .subscriptionBundle: self = .subscriptionBundle
            case .subscriptionSuite: self = .subscriptionSuite

            default:
                Logger.warn(Strings.storeKit.sk2_unknown_product_type(String(describing: type)))
                self = .defaultType
            }
        } else {
            self = Self.parseProductTypePreOS27(type)
        }
        #else
        self = Self.parseProductTypePreOS27(type)
        #endif

    }

    /// Converts a `SK2Product.ProductType` to a StoreProduct.ProductType` using only values
    /// available before OS 27.
    private static func parseProductTypePreOS27(_ type: SK2Product.ProductType) -> StoreProduct.ProductType {
        switch type {
        case .consumable: return .consumable
        case .nonConsumable: return .nonConsumable
        case .nonRenewable: return .nonRenewableSubscription
        case .autoRenewable: return .autoRenewableSubscription

        default:
            Logger.warn(Strings.storeKit.sk2_unknown_product_type(String(describing: type)))
            return .defaultType
        }
    }

}

extension StoreProduct.ProductCategory: Sendable {}
extension StoreProduct.ProductType: Sendable {}
