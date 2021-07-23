//
//  Product.swift
//  Product
//
//  Created by Andrés Boedo on 7/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

public class ProductWrapper: Hashable {
    public static func == (lhs: ProductWrapper, rhs: ProductWrapper) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier
    }

    var localizedDescription: String { fatalError() }

    //    var localizedTitle: String { get }
    //
    var price: Decimal { fatalError() }
    //
    var localizedPriceString: String { fatalError() }
    //
    var productIdentifier: String { fatalError() }
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

    public func hash(into hasher: inout Hasher) {
        fatalError()
    }
}

// struct AnyProductWrapper: ProductWrapper {
//    static func == (lhs: AnyProductWrapper, rhs: AnyProductWrapper) -> Bool {
//        lhs.localizedDescription == rhs.localizedDescription
//    }
//
//    let wrappedProduct: ProductWrapper
//
//    var localizedDescription: String { return wrappedProduct.localizedDescription }
//    var price: Decimal { wrappedProduct.price }
//    var localizedPriceString: String { wrappedProduct.localizedPriceString }
//
//    init<Version: ProductWrapper>(_ productWrapper: Version) {
//        self.wrappedProduct = productWrapper
//    }
// }

@available(iOS 15.0, tvOS 15.0, watchOS 7.0, macOS 12.0, *)
public class SK2ProductWrapper: ProductWrapper {

    init(sk2Product: StoreKit.Product) {
        self.underlyingSK2Product = sk2Product
    }

    public let underlyingSK2Product: StoreKit.Product

    public override var localizedDescription: String {
        return underlyingSK2Product.description
    }

    public override var price: Decimal {
        return underlyingSK2Product.price
    }

    public override var localizedPriceString: String {
        return underlyingSK2Product.displayPrice
    }

    public override var productIdentifier: String {
        return underlyingSK2Product.id
    }

    public override func hash(into hasher: inout Hasher) {
        underlyingSK2Product.hash(into: &hasher)
    }
}

public class SK1ProductWrapper: ProductWrapper {

    private let formatter: NumberFormatter

    public let underlyingSK1Product: SKProduct
    public override var localizedDescription: String {
        return underlyingSK1Product.localizedDescription
    }
    //
    //    public var localizedTitle: String {
    //        return underlyingSK1Product.localizedTitle
    //    }
    //
    public override var price: Decimal {
        return underlyingSK1Product.price as Decimal
    }

    public override var localizedPriceString: String {
        return formatter.string(from: underlyingSK1Product.price) ?? ""
    }

    public override var productIdentifier: String {
        return underlyingSK1Product.productIdentifier
    }

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

    public override func hash(into hasher: inout Hasher) {
        underlyingSK1Product.hash(into: &hasher)
    }

}
