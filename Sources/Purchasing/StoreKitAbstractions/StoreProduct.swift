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

// It's an @objc wrapper of a `StoreProductType`. Swift-only code can use the protocol directly.
/// Type that provides access to all of `StoreKit`'s product type's properties.
@objc(RCStoreProduct) public final class StoreProduct: NSObject, StoreProductType {

    let product: StoreProductType

    /// Designated initializer.
    /// - SeeAlso: ``StoreProduct.from(product:)`` to wrap an instance of `StoreProduct`
    private init(_ product: StoreProductType) {
        self.product = product

        super.init()

        if self.localizedTitle.isEmpty {
            Logger.warn(Strings.offering.product_details_empty_title(productIdentifier: self.productIdentifier))
        }
    }

    /// Creates an instance from any `StoreProductType`.
    /// If `product` is already a wrapped `StoreProduct` then this returns it instead.
    static func from(product: StoreProductType) -> StoreProduct {
        return product as? StoreProduct
            ?? StoreProduct(product)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? StoreProductType)?.productIdentifier
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.productIdentifier)

        return hasher.finalize()
    }

    // Note: this class inherits its docs from `StoreProductType`
    // swiftlint:disable missing_docs

    @objc public var productType: ProductType { self.product.productType }

    @objc public var productCategory: ProductCategory { self.product.productCategory }

    @objc public var localizedDescription: String { self.product.localizedDescription }

    @objc public var localizedTitle: String { self.product.localizedTitle }

    @objc public var currencyCode: String? { self.product.currencyCode }

    // See also `priceDecimalNumber` for Objective-C
    public var price: Decimal { self.product.price }

    @objc public var localizedPriceString: String { self.product.localizedPriceString}

    @objc public var productIdentifier: String { self.product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @objc public var isFamilyShareable: Bool { self.product.isFamilyShareable }

    @objc public var subscriptionGroupIdentifier: String? { self.product.subscriptionGroupIdentifier}

    @objc public var priceFormatter: NumberFormatter? { self.product.priceFormatter }

    @objc public var subscriptionPeriod: SubscriptionPeriod? { self.product.subscriptionPeriod }

    @objc public var introductoryDiscount: StoreProductDiscount? { self.product.introductoryDiscount }

    @objc public var discounts: [StoreProductDiscount] { self.product.discounts }

    // switflint:enable missing_docs
}

/// Type that provides access to all of `StoreKit`'s product type's properties.
internal protocol StoreProductType: Sendable {

    /// The category of this product, whether a subscription or a one-time purchase.

    /// ### Related Symbols:
    /// - ``StoreProduct/productType-swift.property``
    var productCategory: StoreProduct.ProductCategory { get }

    /// The type of product.
    /// - Important: `StoreProduct`s backing SK1 products cannot determine the type.
    ///
    /// ### Related Symbols:
    /// - ``StoreProduct/productCategory-swift.property``
    var productType: StoreProduct.ProductType { get }

    /// A description of the product.
    /// - Note: The description's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedDescription: String { get }

    /// The name of the product.
    /// - Note: The title's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedTitle: String { get }

    /// The currency of the product's price.
    var currencyCode: String? { get }

    /// The decimal representation of the cost of the product, in local currency.
    /// For a string representation of the price to display to customers, use ``localizedPriceString``.
    ///
    /// #### Related Symbols
    /// - ``StoreProduct/pricePerWeek``
    /// - ``StoreProduct/pricePerMonth``
    /// - ``StoreProduct/pricePerYear``
    var price: Decimal { get }

    /// The price of this product using ``StoreProduct/priceFormatter``.
    var localizedPriceString: String { get }

    /// The string that identifies the product to the Apple App Store.
    var productIdentifier: String { get }

    /// A Boolean value that indicates whether the product is available for family sharing in App Store Connect.
    /// Check the value of `isFamilyShareable` to learn whether an in-app purchase is sharable with the family group.
    ///
    /// When displaying in-app purchases in your app, indicate whether the product includes Family Sharing
    /// to help customers make a selection that best fits their needs.
    ///
    /// Configure your in-app purchases to allow Family Sharing in App Store Connect.
    /// For more information about setting up Family Sharing, see Turn-on Family Sharing for in-app purchases.
    ///
    /// #### Related Articles
    /// - https://support.apple.com/en-us/HT201079
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var isFamilyShareable: Bool { get }

    /// The identifier of the subscription group to which the subscription belongs.
    /// All auto-renewable subscriptions must be a part of a group.
    /// You create the group identifiers in App Store Connect.
    /// This property is `nil` if the product is not an auto-renewable subscription.
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    var subscriptionGroupIdentifier: String? { get }

    /// Provides a `NumberFormatter`, useful for formatting the price for displaying.
    /// - Note: This creates a new formatter for every product, which can be slow.
    /// - Note: This will only be `nil` for StoreKit 2 backed products before iOS 16
    /// if the currency code could not be determined. In every other instance, it will never be `nil`.
    var priceFormatter: NumberFormatter? { get }

    /// The period details for products that are subscriptions.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    var subscriptionPeriod: SubscriptionPeriod? { get }

    /// The object containing introductory price information for the product.
    /// If you've set up introductory prices in App Store Connect, the introductory price property will be populated.
    /// This property is `nil` if the product has no introductory price.
    ///
    /// Before displaying UI that offers the introductory price,
    /// you must first determine if the user is eligible to receive it.
    /// #### Related Symbols
    /// - ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:)`` to  determine eligibility.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    var introductoryDiscount: StoreProductDiscount? { get }

    /// An array of subscription offers available for the auto-renewable subscription.
    /// - Note: the current user may or may not be eligible for some of these.
    /// #### Related Symbols
    /// - ``Purchases/promotionalOffer(forProductDiscount:product:)``
    /// - ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
    /// - ``Purchases/eligiblePromotionalOffers(forProduct:)``
    /// - ``StoreProduct/eligiblePromotionalOffers()``
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var discounts: [StoreProductDiscount] { get }

}

public extension StoreProduct {

    /// The decimal representation of the cost of the product, in local currency.
    /// For a string representation of the price to display to customers, use ``localizedPriceString``.
    /// - Note: this is meant for  Objective-C. For Swift, use ``price`` instead.
    ///
    /// #### Related Symbols
    /// - ``pricePerWeek``
    /// - ``pricePerMonth``
    /// - ``pricePerYear``
    @objc(price) var priceDecimalNumber: NSDecimalNumber {
        return self.price as NSDecimalNumber
    }

    /// Calculates the price of this subscription product per day.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var pricePerDay: NSDecimalNumber? {
        return self.subscriptionPeriod?.pricePerDay(withTotalPrice: self.price) as NSDecimalNumber?
    }

    /// Calculates the price of this subscription product per week.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var pricePerWeek: NSDecimalNumber? {
        return self.subscriptionPeriod?.pricePerWeek(withTotalPrice: self.price) as NSDecimalNumber?
    }

    /// Calculates the price of this subscription product per month.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var pricePerMonth: NSDecimalNumber? {
        return self.subscriptionPeriod?.pricePerMonth(withTotalPrice: self.price) as NSDecimalNumber?
    }

    /// Calculates the price of this subscription product per year.
    /// - Returns: `nil` if the product is not a subscription.
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var pricePerYear: NSDecimalNumber? {
        return self.subscriptionPeriod?.pricePerYear(withTotalPrice: self.price) as NSDecimalNumber?
    }

    /// The price of the `introductoryPrice` formatted using ``priceFormatter``.
    /// - Returns: `nil` if there is no `introductoryPrice`.
    @objc var localizedIntroductoryPriceString: String? {
        guard #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) else { return nil }
        return self.formattedString(for: self.introductoryDiscount?.priceDecimalNumber)
    }

    /// The formatted price per week using ``StoreProduct/priceFormatter``.
    /// ### Related Symbols
    /// - ``pricePerWeek``
    /// - ``localizedPricePerMonth``
    /// - ``localizedPricePerYear``
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var localizedPricePerDay: String? {
        return self.formattedString(for: self.pricePerDay)
    }

    /// The formatted price per week using ``StoreProduct/priceFormatter``.
    /// ### Related Symbols
    /// - ``pricePerWeek``
    /// - ``localizedPricePerMonth``
    /// - ``localizedPricePerYear``
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var localizedPricePerWeek: String? {
        return self.formattedString(for: self.pricePerWeek)
    }

    /// The formatted price per month using ``StoreProduct/priceFormatter``.
    /// ### Related Symbols
    /// - ``pricePerMonth``
    /// - ``localizedPricePerWeek``
    /// - ``localizedPricePerYear``
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var localizedPricePerMonth: String? {
        return self.formattedString(for: self.pricePerMonth)
    }

    /// The formatted price per year using ``StoreProduct/priceFormatter``.
    /// ### Related Symbols
    /// - ``pricePerYear``
    /// - ``localizedPricePerWeek``
    /// - ``localizedPricePerMonth``
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc var localizedPricePerYear: String? {
        return self.formattedString(for: self.pricePerYear)
    }

}

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
public extension StoreProduct {
    /// Finds the subset of ``discounts`` that's eligible for the current user.
    /// - Note: if checking for eligibility for a `StoreProductDiscount` fails (for example, if network is down),
    ///   that discount will fail silently and be considered not eligible.
    /// - Warning: this method implicitly relies on ``Purchases`` already being initialized.
    /// #### Related Symbols
    /// - ``discounts``
    func eligiblePromotionalOffers() async -> [PromotionalOffer] {
        return await Purchases.shared.eligiblePromotionalOffers(forProduct: self)
    }
}
#endif

// MARK: - Wrapper constructors / getters

extension StoreProduct {

    @objc
    public convenience init(sk1Product: SK1Product) {
        self.init(SK1StoreProduct(sk1Product: sk1Product))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public convenience init(sk2Product: SK2Product) {
        self.init(SK2StoreProduct(sk2Product: sk2Product))
    }

    /// Returns the `SKProduct` if this `StoreProduct` represents a `StoreKit.SKProduct`.
    @objc public var sk1Product: SK1Product? {
        return (self.product as? SK1StoreProduct)?.underlyingSK1Product
    }

    /// Returns the `Product` if this `StoreProduct` represents a `StoreKit.Product`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Product: SK2Product? {
        return (self.product as? SK2StoreProduct)?.underlyingSK2Product
    }

    var isTestProduct: Bool {
        return self.product is TestStoreProduct
    }

}

// MARK: - Renames

// @available annotations to help users migrating from `SKProduct` to `StoreProduct`
public extension StoreProduct {

    /// The object containing introductory price information for the product.
    @available(iOS, introduced: 11.2, unavailable,
               renamed: "introductoryDiscount", message: "Use StoreProductDiscount instead")
    @available(tvOS, introduced: 11.2, unavailable,
               renamed: "introductoryDiscount", message: "Use StoreProductDiscount instead")
    @available(watchOS, introduced: 6.2, unavailable,
               renamed: "introductoryDiscount", message: "Use StoreProductDiscount instead")
    @available(macOS, introduced: 10.13.2, unavailable,
               renamed: "introductoryDiscount", message: "Use StoreProductDiscount instead")
    @objc var introductoryPrice: SKProductDiscount? { fatalError() }

    /// The locale used to format the price of the product.
    @available(iOS, unavailable, message: "Use localizedPriceString instead")
    @available(tvOS, unavailable, message: "Use localizedPriceString instead")
    @available(watchOS, unavailable, message: "Use localizedPriceString instead")
    @available(macOS, unavailable, message: "Use localizedPriceString instead")
    @objc var priceLocale: Locale { fatalError() }

}

private extension StoreProduct {

    func formattedString(for price: NSDecimalNumber?) -> String? {
        guard let formatter = self.priceFormatter,
              let price = price
        else {
            return nil
        }

        return formatter.string(from: price as NSDecimalNumber)
    }

}
