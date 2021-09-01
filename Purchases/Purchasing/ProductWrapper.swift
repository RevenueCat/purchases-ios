//
//  Product.swift
//  Product
//
//  Created by Andrés Boedo on 7/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCProductWrapper) public class ProductWrapper: NSObject {
    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? ProductWrapper)?.productIdentifier
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
    //    @available(iOS 11.2, *)
    //    var subscriptionPeriod: SKProductSubscriptionPeriod? { get }
    //

    // todo: add product discounts
    //    @available(iOS 11.2, *)
    //    var introductoryPrice: SKProductDiscount? { get }
    //    //
    //    @available(iOS 12.2, *)
    //    var discounts: [SKProductDiscount] { get }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
@objc(RCSK2ProductWrapper) public class SK2ProductWrapper: ProductWrapper {

    // todo: remove when this gets fixed.
    // limiting to arm architecture since builds on beta 5 fail if other archs are included
    #if arch(arm64)
    init(sk2Product: StoreKit.Product) {
        self.underlyingSK2Product = sk2Product
    }

    public let underlyingSK2Product: StoreKit.Product

    @objc public override var localizedDescription: String { underlyingSK2Product.description }

    @objc public override var price: Decimal { underlyingSK2Product.price }

    @objc public override var localizedPriceString: String { underlyingSK2Product.displayPrice }

    @objc public override var productIdentifier: String { underlyingSK2Product.id }

    @objc public override var isFamilyShareable: Bool { underlyingSK2Product.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingSK2Product.displayName }

    @objc public override var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }
    #endif

}

@objc(RCSK1ProductWrapper) public class SK1ProductWrapper: ProductWrapper {

    @objc public let underlyingSK1Product: SKProduct

    @objc public override var localizedDescription: String { return underlyingSK1Product.localizedDescription }

    @objc public override var price: Decimal { return underlyingSK1Product.price as Decimal }

    @objc public override var localizedPriceString: String {
        return formatter.string(from: underlyingSK1Product.price) ?? ""
    }

    @objc public override var productIdentifier: String { return underlyingSK1Product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public override var isFamilyShareable: Bool { underlyingSK1Product.isFamilyShareable }

    @objc public override var localizedTitle: String { underlyingSK1Product.localizedTitle }

    @objc public init(sk1Product: SKProduct) {
        self.underlyingSK1Product = sk1Product
    }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    override public var subscriptionGroupIdentifier: String? { underlyingSK1Product.subscriptionGroupIdentifier }

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingSK1Product.priceLocale
        return formatter
    }()

}
