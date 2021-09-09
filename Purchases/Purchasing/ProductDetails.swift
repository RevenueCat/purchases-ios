//
// Copyright RevenueCat Inc. All Rights Reserved.
//
// Licensed under the MIT License (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// opensource.org/licenses/MIT
//
// ProductDetails.swift
//
// Created by Andrés Boedo on 7/16/21.
//

import Foundation
import StoreKit

/// TypeAlias to the Original In-App Purchase Framework's Product type, called SKProduct
public typealias LegacySKProduct = SKProduct

/// TypeAlias to the New In-App Purchase Framework's Product type, called StoreKit.Product
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias NewSKProduct = StoreKit.Product

@objc(RCProductDetails) public class ProductDetails: NSObject {
    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? ProductDetails)?.productIdentifier
    }

    @objc public var localizedDescription: String { fatalError() }
    @objc public var localizedTitle: String { fatalError() }
    @objc public var price: Decimal { fatalError() }
    @objc public var localizedPriceString: String { fatalError() }
    @objc public var productIdentifier: String { fatalError() }
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public var isFamilyShareable: Bool { fatalError() }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    @objc public var subscriptionGroupIdentifier: String? { fatalError() }

    // todo: it looks like StoreKit 2 doesn't have support for these?
    //    YES if this product has content downloadable using SKDownload
    //    var isDownloadable: Bool { get }
    //
    //    var downloadContentLengths: [NSNumber] { get }
    //
    //    // Version of the downloadable content
    //    var contentVersion: String { get }
    //
    //    var downloadContentVersion: String { get }
    //

    // todo: add subscription period
    // https://github.com/RevenueCat/purchases-ios/issues/849
    //    @available(iOS 11.2, *)
    //    var subscriptionPeriod: SKProductSubscriptionPeriod? { get }
    //

    // todo: add product discounts
    // https://github.com/RevenueCat/purchases-ios/issues/848
    //    @available(iOS 11.2, *)
    //    var introductoryPrice: SKProductDiscount? { get }
    //    //
    //    @available(iOS 12.2, *)
    //    var discounts: [SKProductDiscount] { get }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
@objc(RCSK2ProductDetails) public class SK2ProductDetails: ProductDetails {

    init(sk2Product: StoreKit.Product) {
        self.underlyingNewSKProduct = sk2Product
    }

    public let underlyingNewSKProduct: StoreKit.Product

    @objc public override var localizedDescription: String { underlyingNewSKProduct.description }

    @objc public override var price: Decimal { underlyingNewSKProduct.price }

    @objc public override var localizedPriceString: String { underlyingNewSKProduct.displayPrice }

    @objc public override var productIdentifier: String { underlyingNewSKProduct.id }

    @objc public override var isFamilyShareable: Bool { underlyingNewSKProduct.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingNewSKProduct.displayName }

    @objc public override var subscriptionGroupIdentifier: String? {
        underlyingNewSKProduct.subscription?.subscriptionGroupID
    }

}

@objc(RCSK1ProductDetails) public class SK1ProductDetails: ProductDetails {

    @objc public init(legacySKProduct: LegacySKProduct) {
        self.underlyingLegacySKProduct = legacySKProduct
    }

    @objc public let underlyingLegacySKProduct: LegacySKProduct

    @objc public override var localizedDescription: String { return underlyingLegacySKProduct.localizedDescription }

    @objc public override var price: Decimal { return underlyingLegacySKProduct.price as Decimal }

    @objc public override var localizedPriceString: String {
        return formatter.string(from: underlyingLegacySKProduct.price) ?? ""
    }

    @objc public override var productIdentifier: String { return underlyingLegacySKProduct.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public override var isFamilyShareable: Bool { underlyingLegacySKProduct.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingLegacySKProduct.localizedTitle }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    override public var subscriptionGroupIdentifier: String? { underlyingLegacySKProduct.subscriptionGroupIdentifier }

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingLegacySKProduct.priceLocale
        return formatter
    }()

}
