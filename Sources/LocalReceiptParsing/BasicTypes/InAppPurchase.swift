//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InAppPurchase.swift
//
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

extension AppleReceipt {

    /// An individual purchase inside a receipt.
    public struct InAppPurchase: Equatable {

        /// The number of items purchased.
        ///
        /// This value corresponds to the `quantity` property of the `SKPayment` object
        /// stored in the transaction’s payment property.
        public let quantity: Int

        /// The product identifier of the item that was purchased.
        ///
        /// This value corresponds to the `productIdentifier` property of the `SKPayment` object
        /// stored in the transaction’s payment property.
        public let productId: String

        /// The transaction identifier of the item that was purchased.
        ///
        /// This value corresponds to the transaction’s `transactionIdentifier` property.
        /// For a transaction that restores a previous transaction,
        /// this value is different from the transaction identifier
        /// of the original purchase transaction.
        /// In an auto-renewable subscription receipt, a new value for the transaction identifier is generated
        /// every time the subscription automatically renews or is restored on a new device.
        public let transactionId: String

        /// For a transaction that restores a previous transaction, the transaction identifier
        /// of the original transaction.
        /// Otherwise, identical to the transaction identifier.
        ///
        /// This value corresponds to the original transaction’s `transactionIdentifier` property.
        /// This value is the same for all receipts that have been generated for a specific subscription.
        /// This value is useful for relating together multiple iOS 6 style transaction receipts
        /// for the same individual customer’s subscription.
        public let originalTransactionId: String?

        /// The type of product that this purchase represents.
        public let productType: ProductType

        /// The date and time that the item was purchased.
        ///
        /// This value corresponds to the transaction’s `transactionDate` property.
        /// For a transaction that restores a previous transaction, the purchase date is
        /// the same as the original purchase date.
        /// Use Original Purchase Date to get the date of the original transaction.
        /// In an auto-renewable subscription receipt, the purchase date is the date when the subscription was either
        /// purchased or renewed (with or without a lapse).
        /// For an automatic renewal that occurs on the expiration date of the current period,
        /// the purchase date is the start date of the next period,
        /// which is identical to the end date of the current period.
        public let purchaseDate: Date

        /// For a transaction that restores a previous transaction, the date of the original transaction.
        ///
        /// This value corresponds to the original transaction’s `transactionDate` property.
        /// In an auto-renewable subscription receipt, this indicates the beginning of the subscription period,
        /// even if the subscription has been renewed.
        public let originalPurchaseDate: Date?

        /// The expiration date for the subscription.
        ///
        /// This is only present for auto-renewable subscription receipts.
        /// Use this value to identify the date when the subscription will renew or expire, to determine if a customer
        /// should have access to content or service.
        /// After validating the latest receipt, if the subscription expiration date
        /// for the latest renewal transaction is a past date, it is safe to assume that the subscription has expired.
        public let expiresDate: Date?

        /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation.
        /// For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
        /// Treat a canceled receipt the same as if no purchase had ever been made.
        ///
        /// - Note: A canceled in-app purchase remains in the receipt indefinitely.
        /// Only applicable if the refund was for a non-consumable product, an auto-renewable subscription,
        /// a non-renewing subscription, or for a free subscription.
        public let cancellationDate: Date?

        /// For a subscription, whether or not it is in the free trial period.
        ///
        /// This is only present for auto-renewable subscription receipts.
        /// `true` if the customer’s subscription is currently in the free trial period, or `false` if not.
        ///
        /// - Note: If a previous subscription period in the receipt has the value `true` for either
        /// the ``isInTrialPeriod`` or the ``isInIntroOfferPeriod`` key,
        /// the user is not eligible for a free trial or introductory price within that subscription group.
        public let isInTrialPeriod: Bool?

        /// For an auto-renewable subscription, whether or not it is in the introductory price period.
        ///
        /// This is only present for auto-renewable subscription receipts.
        /// The value for this key is `true` if the customer’s subscription is currently in
        /// an introductory price period, or `false` if not.
        ///
        /// - Note: If a previous subscription period in the receipt has the value `true` for either
        /// the is``isInTrialPeriod`` or the  ``isInIntroOfferPeriod`` key, the user is not eligible for
        /// a free trial or introductory price within that subscription group.
        public let isInIntroOfferPeriod: Bool?

        /// The primary key for identifying subscription purchases.
        ///
        /// This value is a unique ID that identifies purchase events across devices,
        /// including subscription renewal purchase events.
        public let webOrderLineItemId: Int64?

        /// The identifier for the ``PromotionalOffer`` used when purchasing this item.
        public let promotionalOfferIdentifier: String?

    }

}

extension AppleReceipt.InAppPurchase {

    var isActiveSubscription: Bool {
        guard self.isSubscription, let expiration = self.expiresDate else { return false }

        return expiration >= Date()
    }

    var isExpiredSubscription: Bool {
        guard self.isSubscription, let expiration = self.expiresDate else { return false }

        return expiration < Date()
    }

    var purchaseDateEqualsExpiration: Bool {
        guard self.isSubscription, let expiration = self.expiresDate else { return false }

        return abs(self.purchaseDate.timeIntervalSince(expiration)) <= Self.purchaseAndExpirationEqualThreshold
    }

    /// Seconds between purchase and expiration to consider both equal.
    /// 5 provides some margin for error, while still covering the shortest possible
    /// subscription length (weekly subscriptions with `TimeRate.monthlyRenewalEveryThirtySeconds`.
    private static let purchaseAndExpirationEqualThreshold: TimeInterval = 5

}

extension AppleReceipt.InAppPurchase {

    /// The type of product that a ``AppleReceipt/InAppPurchase`` represents.
    public enum ProductType: Int {

        /// Unable to determine product type.
        case unknown = -1

        /// A non-consumable in-app purchase.
        case nonConsumable = 0

        /// A consumable in-app purchase.
        case consumable = 1

        /// A non-renewing subscription.
        case nonRenewingSubscription = 2

        /// An auto-renewable subscription.
        case autoRenewableSubscription = 3

    }

}

extension AppleReceipt.InAppPurchase {

    var isSubscription: Bool {
        switch self.productType {
        case .unknown: return self.expiresDate != nil
        case .nonConsumable, .consumable: return false
        case .nonRenewingSubscription, .autoRenewableSubscription: return true
        }
    }

}

// MARK: -

extension AppleReceipt.InAppPurchase.ProductType: Sendable {}

#if swift(>=5.7)
extension AppleReceipt.InAppPurchase: Sendable {}
#else
// `@unchecked` because:
// - `Date` is not `Sendable` until Swift 5.7
extension AppleReceipt.InAppPurchase: @unchecked Sendable {}
#endif

extension AppleReceipt.InAppPurchase.ProductType: Codable {}
extension AppleReceipt.InAppPurchase: Codable {}

extension AppleReceipt.InAppPurchase: CustomDebugStringConvertible {

    // swiftlint:disable:next missing_docs
    public var debugDescription: String {
        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
