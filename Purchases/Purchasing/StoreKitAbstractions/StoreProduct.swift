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
    fileprivate override init() {
        super.init()

        precondition(type(of: self) != StoreProduct.self, "StoreProduct is an abstract class")

        if self.localizedTitle.isEmpty {
            Logger.warn(Strings.offering.product_details_empty_title(productIdentifier: self.productIdentifier))
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? StoreProduct)?.productIdentifier
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.productIdentifier)

        return hasher.finalize()
    }

    /// A description of the product.
    /// - Note: The description's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    @objc public var localizedDescription: String { fatalError() }

    /// The name of the product.
    /// - Note: The title's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    @objc public var localizedTitle: String { fatalError() }

    /// The decimal representation of the cost of the product, in local currency.
    /// For a string representation of the price to display to customers, use ``localizedPriceString``.
    /// - Seealso: `pricePerMonth`.
    @objc public var price: Decimal { fatalError() }

    /// The price of this product using ``priceFormatter``.
    @objc public var localizedPriceString: String { fatalError() }

    /// The string that identifies the product to the Apple App Store.
    @objc public var productIdentifier: String { fatalError() }

    /// A Boolean value that indicates whether the product is available for family sharing in App Store Connect.
    /// Check the value of `isFamilyShareable` to learn whether an in-app purchase is sharable with the family group.
    ///
    /// When displaying in-app purchases in your app, indicate whether the product includes Family Sharing
    /// to help customers make a selection that best fits their needs.
    ///
    /// Configure your in-app purchases to allow Family Sharing in App Store Connect.
    /// For more information about setting up Family Sharing, see Turn-on Family Sharing for in-app purchases.
    /// - Seealso: https://support.apple.com/en-us/HT201079
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public var isFamilyShareable: Bool { fatalError() }

    /// The identifier of the subscription group to which the subscription belongs.
    /// All auto-renewable subscriptions must be a part of a group.
    /// You create the group identifiers in App Store Connect.
    /// This property is `nil` if the product is not an auto-renewable subscription.
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    @objc public var subscriptionGroupIdentifier: String? { fatalError() }

    /// Provides a `NumberFormatter`, useful for formatting the price for displaying.
    /// - Note: This creates a new formatter for every product, which can be slow.
    /// - Returns: `nil` for StoreKit 2 backed products if the currency code could not be determined.
    @objc public var priceFormatter: NumberFormatter? { fatalError() }

    /// The period details for products that are subscriptions.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc public var subscriptionPeriod: SubscriptionPeriod? { fatalError() }

    /// The object containing introductory price information for the product.
    /// If you've set up introductory prices in App Store Connect, the introductory price property will be populated.
    /// This property is `nil` if the product has no introductory price.
    ///
    /// Before displaying UI that offers the introductory price,
    /// you must first determine if the user is eligible to receive it.
    /// - Seealso: `Purchases.checkTrialOrIntroductoryPriceEligibility` to  determine eligibility.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public var introductoryPrice: PromotionalOffer? { fatalError() }

    /// An array of subscription offers available for the auto-renewable subscription.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public var discounts: [PromotionalOffer] { fatalError() }
}

public extension StoreProduct {

    /// Calculates the price of this subscription product per month.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var pricePerMonth: NSDecimalNumber? {
        guard let period = self.subscriptionPeriod,
              period.unit != .unknown else {
                  return nil
              }

        return period.pricePerMonth(withTotalPrice: self.price) as NSDecimalNumber?
    }

}

// MARK: - Subclasses

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
        // note: if we ever need more information from the jsonRepresentation object, we
        // should use Codable or another decoding method to clean up this code.
        guard let attributes = jsonDict["attributes"] as? [String: Any],
              let offers = attributes["offers"] as? [[String: Any]],
              let currencyCode: String = offers.first?["currencyCode"] as? String else {
            Logger.appleError("Can't initialize priceFormatter for SK2 product! Could not find the currency code")
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .autoupdatingCurrent
        return formatter
    }

    @objc public override var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingSK2Product.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

    @objc public override var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
    }

    @objc public override var introductoryPrice: PromotionalOffer? {
        self.underlyingSK2Product.subscription?.introductoryOffer
            .map(PromotionalOffer.init)
    }

    @objc public override var discounts: [PromotionalOffer] {
        (self.underlyingSK2Product.subscription?.promotionalOffers ?? [])
            .compactMap(PromotionalOffer.init)
    }

}

public extension StoreProduct {
    /// The price of the `introductoryPrice` formatted using ``priceFormatter``.
    /// - Returns: `nil` if there is no `introductoryPrice`.
    @objc var localizedIntroductoryPriceString: String? {
        guard #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *),
              let formatter = self.priceFormatter,
              let intro = self.introductoryPrice
        else {
            return nil
        }

        return formatter.string(from: intro.price as NSDecimalNumber)
    }
}

// MARK: - Subsclasses

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

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc public override var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public override var introductoryPrice: PromotionalOffer? {
        return self.underlyingSK1Product.introductoryPrice
            .map(PromotionalOffer.init)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public override var discounts: [PromotionalOffer] {
        return self.underlyingSK1Product.discounts
            .map(PromotionalOffer.init)
    }

}
