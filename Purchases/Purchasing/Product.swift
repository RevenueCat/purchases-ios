//
//  Product.swift
//  Product
//
//  Created by Andrés Boedo on 7/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

public protocol Product {

    var localizedDescription: String { get }

    //    var localizedTitle: String { get }
    //
        var price: Decimal { get }
    //
        var localizedPriceString: String { get }
    //
    //    var productIdentifier: String { get }
    //
    //    // YES if this product has content downloadable using SKDownload
    //    var isDownloadable: Bool { get }
    //
    //    // YES if this product allows for sharing among family members
    //    @available(iOS 14.0, *)
    //    var isFamilyShareable: Bool { get }
    //
    //
    //    var downloadContentLengths: [NSNumber] { get }
    //
    //    // Version of the downloadable content
    //    var contentVersion: String { get }
    //
    //    var downloadContentVersion: String { get }
    //
    //    @available(iOS 11.2, *)
    //    var subscriptionPeriod: SKProductSubscriptionPeriod? { get }
    //
    //    @available(iOS 11.2, *)
    //    var introductoryPrice: SKProductDiscount? { get }
    //
    //    @available(iOS 12.0, *)
    //    var subscriptionGroupIdentifier: String? { get }
    //
    //    @available(iOS 12.2, *)
    //    var discounts: [SKProductDiscount] { get }
}

@available(iOS 15.0, tvOS 15.0, watchOS 7.0, macOS 12.0, *)
public struct SK2ProductWrapper: Product {
    public let underlyingSK2Product: StoreKit.Product

    public var localizedDescription: String {
        return underlyingSK2Product.description
    }

    init(sk2Product: StoreKit.Product) {
        self.underlyingSK2Product = sk2Product
    }

    public var price: Decimal {
        return underlyingSK2Product.price
    }

    public var localizedPriceString: String {
        return underlyingSK2Product.displayPrice
    }
}

public struct SK1ProductWrapper: Product {
    private let formatter: NumberFormatter

    public let underlyingSK1Product: SKProduct
    public var localizedDescription: String {
        return underlyingSK1Product.localizedDescription
    }
    //
    //    public var localizedTitle: String {
    //        return underlyingSK1Product.localizedTitle
    //    }
    //
    public var price: Decimal {
        return underlyingSK1Product.price as Decimal
    }

    public var localizedPriceString: String {
        return formatter.string(from: underlyingSK1Product.price) ?? ""
    }
    //
    //    public var productIdentifier: String {
    //        return underlyingSK1Product.productIdentifier
    //    }

    // YES if this product has content downloadable using SKDownload
    //    public var isDownloadable: Bool
    //    public var downloadContentLengths: [NSNumber]
    //    public var downloadContentVersion: String

    // YES if this product allows for sharing among family members
    //    @available(iOS 14.0, *)
    //    public private(set) var isFamilyShareable: Bool

    //    @available(iOS 11.2, *)
    //    open var subscriptionPeriod: SKProductSubscriptionPeriod?

    //    @available(iOS 11.2, *)
    //    open var introductoryPrice: SKProductDiscount?

    //    @available(iOS 12.0, *)
    //    public private(set) var subscriptionGroupIdentifier: String?

    //    @available(iOS 12.2, *)
    //    open var discounts: [SKProductDiscount]

    // Version of the downloadable content
    //    public private(set) var contentVersion: String

    init(sk1Product: SKProduct) {
        self.underlyingSK1Product = sk1Product

        self.formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingSK1Product.priceLocale
    }
}
