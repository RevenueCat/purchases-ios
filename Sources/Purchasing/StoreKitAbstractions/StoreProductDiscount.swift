//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductDiscount.swift
//
//  Created by Joshua Liebowitz on 7/2/21.
//

import Foundation
import StoreKit

/// TypeAlias to StoreKit 1's Discount type, called `SKProductDiscount`
@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
public typealias SK1ProductDiscount = SKProductDiscount

/// TypeAlias to StoreKit 2's Discount type, called `StoreKit.Product.SubscriptionOffer`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2ProductDiscount = StoreKit.Product.SubscriptionOffer

/// Type that wraps `StoreKit.Product.SubscriptionOffer` and `SKProductDiscount`
/// and provides access to their properties.
/// Information about a subscription offer that you configured in App Store Connect.
@objc(RCStoreProductDiscount)
public final class StoreProductDiscount: NSObject, StoreProductDiscountType {

    /// The payment mode for a `StoreProductDiscount`
    /// Indicates how the product discount price is charged.
    @objc(RCPaymentMode)
    public enum PaymentMode: Int {

        /// Price is charged one or more times
        case payAsYouGo = 0
        /// Price is charged once in advance
        case payUpFront = 1
        /// No initial charge
        case freeTrial = 2

    }

    /// The discount type for a `StoreProductDiscount`
    /// Wraps `SKProductDiscount.Type` if this `StoreProductDiscount` represents a `SKProductDiscount`.
    /// Wraps  `Product.SubscriptionOffer.OfferType` if this `StoreProductDiscount` represents
    /// a `Product.SubscriptionOffer`.
    @objc(RCDiscountType)
    public enum DiscountType: Int {

        /// Introductory offer
        case introductory = 0
        /// Promotional offer for subscriptions
        case promotional = 1
    }

    private let discount: StoreProductDiscountType

    init(_ discount: StoreProductDiscountType) {
        self.discount = discount

        super.init()
    }

    // Note: this class inherits its docs from `StoreProductDiscountType`
    // swiftlint:disable missing_docs

    @objc public var offerIdentifier: String? { self.discount.offerIdentifier }
    @objc public var currencyCode: String? { self.discount.currencyCode }
    // See also `priceDecimalNumber` for Objective-C
    public var price: Decimal { self.discount.price }
    @objc public var localizedPriceString: String { self.discount.localizedPriceString }
    @objc public var paymentMode: PaymentMode { self.discount.paymentMode }
    @objc public var subscriptionPeriod: SubscriptionPeriod { self.discount.subscriptionPeriod }
    @objc public var numberOfPeriods: Int { self.discount.numberOfPeriods }
    @objc public var type: DiscountType { self.discount.type }

    // swiftlint:enable missing_docs

    /// Creates an instance from any `StoreProductDiscountType`.
    /// If `discount` is already a wrapped `StoreProductDiscount` then this returns it instead.
    static func from(discount: StoreProductDiscountType) -> StoreProductDiscount {
        return discount as? StoreProductDiscount
        ?? StoreProductDiscount(discount)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? StoreProductDiscountType else { return false }

        return Data(discount: self) == Data(discount: other)
    }

    public override var hash: Int {
        return Data(discount: self).hashValue
    }

}

extension StoreProductDiscount: Sendable {}
extension StoreProductDiscount.PaymentMode: Sendable {}
extension StoreProductDiscount.DiscountType: Sendable {}

public extension StoreProductDiscount {

    /// The discount price of the product in the local currency.
    /// - Note: this is meant for  Objective-C. For Swift, use ``price`` instead.
    @objc(price) var priceDecimalNumber: NSDecimalNumber {
        return self.price as NSDecimalNumber
    }

}

extension StoreProductDiscount {

    /// Used to represent `StoreProductDiscount/id`. Not for public use.
    public struct Data: Hashable {
        private var offerIdentifier: String?
        private var currencyCode: String?
        private var price: Decimal
        private var localizedPriceString: String
        private var paymentMode: StoreProductDiscount.PaymentMode
        private var subscriptionPeriod: SubscriptionPeriod
        private var numberOfPeriods: Int
        private var type: StoreProductDiscount.DiscountType

        fileprivate init(discount: StoreProductDiscountType) {
            self.offerIdentifier = discount.offerIdentifier
            self.currencyCode = discount.currencyCode
            self.price = discount.price
            self.localizedPriceString = discount.localizedPriceString
            self.paymentMode = discount.paymentMode
            self.subscriptionPeriod = discount.subscriptionPeriod
            self.numberOfPeriods = discount.numberOfPeriods
            self.type = discount.type
        }
    }

}

/// The details of an introductory offer or a promotional offer for an auto-renewable subscription.
internal protocol StoreProductDiscountType: Sendable {

    // Note: this is only `nil` for SK1 products before iOS 12.2.
    // It can become `String` once it's not longer supported.
    /// A string used to uniquely identify a discount offer for a product.
    var offerIdentifier: String? { get }

    /// The currency of the product's price.
    var currencyCode: String? { get }

    /// The discount price of the product in the local currency.
    var price: Decimal { get }

    /// The price of this product discount formatted for locale.
    var localizedPriceString: String { get }

    /// The payment mode for this product discount.
    var paymentMode: StoreProductDiscount.PaymentMode { get }

    /// The period for the product discount.
    var subscriptionPeriod: SubscriptionPeriod { get }

    /// The number of periods the product discount is available.
    /// This is `1` for ``StoreProductDiscount/PaymentMode-swift.enum/payUpFront``
    /// and ``StoreProductDiscount/PaymentMode-swift.enum/freeTrial``, but can be
    /// more than 1 for ``StoreProductDiscount/PaymentMode-swift.enum/payAsYouGo``.
    ///
    /// - Note:
    /// A product discount may be available for one or more periods.
    /// The period, defined in `subscriptionPeriod`, is a set number of days, weeks, months, or years.
    /// The total length of time that a product discount is available is calculated by
    /// multiplying the `numberOfPeriods` by the period.
    /// Note that the discount period is independent of the product subscription period.
    var numberOfPeriods: Int { get }

    /// The type of product discount.
    var type: StoreProductDiscount.DiscountType { get }

}

// MARK: - Wrapper constructors / getters

extension StoreProductDiscount {

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    internal convenience init?(sk1Discount: SK1ProductDiscount) {
        guard let discount = SK1StoreProductDiscount(sk1Discount: sk1Discount) else { return nil }

        self.init(discount)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init?(sk2Discount: SK2ProductDiscount, currencyCode: String?) {
        guard let discount = SK2StoreProductDiscount(sk2Discount: sk2Discount,
                                                     currencyCode: currencyCode) else { return nil }

        self.init(discount)
    }

    /// Returns the `SK1ProductDiscount` if this `StoreProductDiscount` represents a `SKProductDiscount`.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    @objc public var sk1Discount: SK1ProductDiscount? {
        return (self.discount as? SK1StoreProductDiscount)?.underlyingSK1Discount
    }

    /// Returns the `SK2ProductDiscount` if this `StoreProductDiscount` represents a `Product.SubscriptionOffer`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Discount: SK2ProductDiscount? {
        return (self.discount as? SK2StoreProductDiscount)?.underlyingSK2Discount
    }

}

// MARK: - Encodable

extension StoreProductDiscount: Encodable {

    private enum CodingKeys: String, CodingKey {

        case offerIdentifier = "offer_identifier"
        case price = "price"
        case paymentMode = "payment_mode"

    }

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.offerIdentifier, forKey: .offerIdentifier)
        // Note: price is encoded price as `String` (using `NSDecimalNumber.description`)
        // to preserve precision and avoid values like "1.89999999"
        try container.encode((self.price as NSDecimalNumber).description, forKey: .price)
        try container.encode(self.paymentMode, forKey: .paymentMode)
    }

}

extension StoreProductDiscount.DiscountType {
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    static func from(sk1Discount: SK1ProductDiscount) -> Self? {
        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            switch sk1Discount.type {
            case .introductory:
                return .introductory
            case .subscription:
                return .promotional
            @unknown default:
                return nil
            }
        } else {
            return nil
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func from(sk2Discount: SK2ProductDiscount) -> Self? {
        switch sk2Discount.type {
        case SK2ProductDiscount.OfferType.introductory:
            return .introductory
        case SK2ProductDiscount.OfferType.promotional:
            return .promotional
        default:
            Logger.warn(Strings.storeKit.unknown_sk2_product_discount_type(rawValue: sk2Discount.type.rawValue))
            return nil
        }
    }
}

extension StoreProductDiscount.PaymentMode: Encodable {}

extension StoreProductDiscount: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: Data { return Data(discount: self) }

}
