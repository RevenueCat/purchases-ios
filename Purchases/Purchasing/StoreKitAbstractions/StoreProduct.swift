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

// Note: this class inherits its docs from `StoreProductType`
// It's an @objc wrapper of a `StoreProductType`. Swift-only code can use the protocol directly.
/// Type that provides access to all of `StoreKit`'s product type's properties.
@objc(RCStoreProduct) public final class StoreProduct: NSObject, StoreProductType {

    let product: StoreProductType

    /// Designated initializer.
    /// - Seealso: ``StoreProduct.from(product:)`` to wrap an instance of `StoreProduct`
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

    @objc public var localizedDescription: String { self.product.localizedDescription }

    @objc public var localizedTitle: String { self.product.localizedTitle }

    @objc public var price: Decimal { self.product.price }

    @objc public var localizedPriceString: String { self.product.localizedPriceString}

    @objc public var productIdentifier: String { self.product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    @objc public var isFamilyShareable: Bool { self.product.isFamilyShareable }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    @objc public var subscriptionGroupIdentifier: String? { self.product.subscriptionGroupIdentifier}

    @objc public var priceFormatter: NumberFormatter? { self.product.priceFormatter }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc public var subscriptionPeriod: SubscriptionPeriod? { self.product.subscriptionPeriod }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public var introductoryPrice: PromotionalOffer? { self.product.introductoryPrice }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public var discounts: [PromotionalOffer] { self.product.discounts }

}

/// Type that provides access to all of `StoreKit`'s product type's properties.
internal protocol StoreProductType {

    /// A description of the product.
    /// - Note: The description's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedDescription: String { get }

    /// The name of the product.
    /// - Note: The title's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedTitle: String { get }

    /// The decimal representation of the cost of the product, in local currency.
    /// For a string representation of the price to display to customers, use ``localizedPriceString``.
    /// - Seealso: `pricePerMonth`.
    var price: Decimal { get }

    /// The price of this product using ``priceFormatter``.
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
    /// - Seealso: https://support.apple.com/en-us/HT201079
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    var isFamilyShareable: Bool { get }

    /// The identifier of the subscription group to which the subscription belongs.
    /// All auto-renewable subscriptions must be a part of a group.
    /// You create the group identifiers in App Store Connect.
    /// This property is `nil` if the product is not an auto-renewable subscription.
    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    var subscriptionGroupIdentifier: String? { get }

    /// Provides a `NumberFormatter`, useful for formatting the price for displaying.
    /// - Note: This creates a new formatter for every product, which can be slow.
    /// - Returns: `nil` for StoreKit 2 backed products if the currency code could not be determined.
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
    /// - Seealso: `Purchases.checkTrialOrIntroductoryPriceEligibility` to  determine eligibility.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var introductoryPrice: PromotionalOffer? { get }

    /// An array of subscription offers available for the auto-renewable subscription.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var discounts: [PromotionalOffer] { get }

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

// MARK: - Wrapper constructors / getters

extension StoreProduct {

    internal convenience init(sk1Product: SK1Product) {
        self.init(SK1StoreProduct(sk1Product: sk1Product))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Product: SK2Product) {
        self.init(SK2StoreProduct(sk2Product: sk2Product))
    }

    /// Returns the `SK1Product` if this `StoreProducts` contains one.
    var sk1Product: SK1Product? {
        return (self.product as? SK1StoreProduct)?.underlyingSK1Product
    }

    /// Returns the `SK2Product` if this `StoreProducts` contains one.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    var sk2Product: SK2Product? {
        return (self.product as? SK2StoreProduct)?.underlyingSK2Product
    }

}

// MARK: - Subclasses

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreProduct: StoreProductType {

    init(sk2Product: SK2Product) {
        self._underlyingSK2Product = sk2Product
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // So instead, we store the underlying product as Any and wrap it with casting.
    // https://openradar.appspot.com/radar?id=4970535809187840
    private let _underlyingSK2Product: Any
    var underlyingSK2Product: SK2Product {
        // swiftlint:disable:next force_cast
        _underlyingSK2Product as! SK2Product
    }

    var localizedDescription: String { underlyingSK2Product.description }

    var price: Decimal { underlyingSK2Product.price }

    var localizedPriceString: String { underlyingSK2Product.displayPrice }

    var productIdentifier: String { underlyingSK2Product.id }

    var isFamilyShareable: Bool { underlyingSK2Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK2Product.displayName }

    var priceFormatter: NumberFormatter? {
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

    var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingSK2Product.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryPrice: PromotionalOffer? {
        self.underlyingSK2Product.subscription?.introductoryOffer
            .map(PromotionalOffer.init)
    }

    var discounts: [PromotionalOffer] {
        (self.underlyingSK2Product.subscription?.promotionalOffers ?? [])
            .compactMap(PromotionalOffer.init)
    }

}

internal struct SK1StoreProduct: StoreProductType {

    init(sk1Product: SK1Product) {
        self.underlyingSK1Product = sk1Product
    }

    let underlyingSK1Product: SK1Product

    var localizedDescription: String { return underlyingSK1Product.localizedDescription }

    var price: Decimal { return underlyingSK1Product.price as Decimal }

    var localizedPriceString: String {
        return priceFormatter?.string(from: underlyingSK1Product.price) ?? ""
    }

    var productIdentifier: String { return underlyingSK1Product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    var isFamilyShareable: Bool { underlyingSK1Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK1Product.localizedTitle }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    var subscriptionGroupIdentifier: String? { underlyingSK1Product.subscriptionGroupIdentifier }

    var priceFormatter: NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingSK1Product.priceLocale
        return formatter
    }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var introductoryPrice: PromotionalOffer? {
        return self.underlyingSK1Product.introductoryPrice
            .map(PromotionalOffer.init)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var discounts: [PromotionalOffer] {
        return self.underlyingSK1Product.discounts
            .map(PromotionalOffer.init)
    }

}

// MARK: - Extensions

extension SK1StoreProduct: Hashable {

    static func == (lhs: SK1StoreProduct, rhs: SK1StoreProduct) -> Bool {
        return lhs.underlyingSK1Product == rhs.underlyingSK1Product
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingSK1Product)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProduct: Hashable {

    static func == (lhs: SK2StoreProduct, rhs: SK2StoreProduct) -> Bool {
        return lhs.underlyingSK2Product == rhs.underlyingSK2Product
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingSK2Product)
    }

}
