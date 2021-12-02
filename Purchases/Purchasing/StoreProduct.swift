//
// Copyright RevenueCat Inc. All Rights Reserved.
//
// Licensed under the MIT License (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// opensource.org/licenses/MIT
//
// StoreProduct.swift
//
// Created by Andrés Boedo on 7/16/21.
//

import Foundation
import StoreKit

/// TypeAlias to StoreKit 1's Product type, called `StoreKit/SKProduct`
public typealias SK1Product = SKProduct

/// TypeAlias to StoreKit 2's Product type, called `StoreKit.Product`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2Product = StoreKit.Product

/// Abstract class that provides access to all of StoreKit's product type's properties.
@objc(RCStoreProduct) public class StoreProduct: NSObject {
    public override init() {
        super.init()

        if self.localizedTitle.isEmpty {
            Logger.warn(Strings.offering.product_details_empty_title(productIdentifier: self.productIdentifier))
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? StoreProduct)?.productIdentifier
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

    @objc public var priceFormatter: NumberFormatter? { fatalError() }

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
@objc(RCSK2StoreProduct) public class SK2StoreProduct: StoreProduct {

    init(sk2Product: SK2Product) {
        self._underlyingSK2Product = sk2Product

        super.init()
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // So instead, we store the underlying product as Any and wrap it with casting.
    // https://openradar.appspot.com/radar?id=4970535809187840
    private var _underlyingSK2Product: Any
    public var underlyingSK2Product: SK2Product {
        // swiftlint:disable:next force_cast
        get { _underlyingSK2Product as! SK2Product }
        set { _underlyingSK2Product = newValue }
    }

    @objc public override var localizedDescription: String { underlyingSK2Product.description }

    @objc public override var price: Decimal { underlyingSK2Product.price }

    @objc public override var localizedPriceString: String { underlyingSK2Product.displayPrice }

    @objc public override var productIdentifier: String { underlyingSK2Product.id }

    @objc public override var isFamilyShareable: Bool { underlyingSK2Product.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingSK2Product.displayName }

    @objc public override var priceFormatter: NumberFormatter? {
        guard let attributes = jsonDict["attributes"] as? [String: Any],
              let offers = attributes["offers"] as? [[String: Any]],
              let currencyCode: String = offers.first?["currencyCode"] as? String else {
            Logger.appleError("Can't initialize priceFormatter for SK2 product! Could not find the currency code")
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter
    }

    @objc public override var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingSK2Product.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

}

@objc(RCSK1StoreProduct) public class SK1StoreProduct: StoreProduct {

    @objc public init(sk1Product: SK1Product) {
        self.underlyingSK1Product = sk1Product

        super.init()
    }

    @objc public let underlyingSK1Product: SK1Product

    @objc public override var localizedDescription: String { return underlyingSK1Product.localizedDescription }

    @objc public override var price: Decimal { return underlyingSK1Product.price as Decimal }

    @objc public override var localizedPriceString: String {
        return priceFormatter?.string(from: underlyingSK1Product.price) ?? ""
    }

    @objc public override var productIdentifier: String { return underlyingSK1Product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public override var isFamilyShareable: Bool { underlyingSK1Product.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingSK1Product.localizedTitle }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    override public var subscriptionGroupIdentifier: String? { underlyingSK1Product.subscriptionGroupIdentifier }

    @objc public override var priceFormatter: NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingSK1Product.priceLocale
        return formatter
    }

}
