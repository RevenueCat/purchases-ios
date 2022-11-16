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

    public struct InAppPurchase: Equatable {

        public let quantity: Int
        public let productId: String
        public let transactionId: String
        public let originalTransactionId: String?
        public let productType: ProductType
        public let purchaseDate: Date
        public let originalPurchaseDate: Date?
        public let expiresDate: Date?
        public let cancellationDate: Date?
        public let isInTrialPeriod: Bool?
        public let isInIntroOfferPeriod: Bool?
        public let webOrderLineItemId: Int64?
        public let promotionalOfferIdentifier: String?

    }

}

public extension AppleReceipt.InAppPurchase {

    var isActiveSubscription: Bool {
        guard self.isSubscription, let expiration = self.expiresDate else { return false }

        return expiration > Date()
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

    public enum ProductType: Int {

        case unknown = -1,
        nonConsumable,
        consumable,
        nonRenewingSubscription,
        autoRenewableSubscription

    }

}

extension AppleReceipt.InAppPurchase {

    public var isSubscription: Bool {
        switch self.productType {
        case .unknown: return self.expiresDate != nil
        case .nonConsumable, .consumable: return false
        case .nonRenewingSubscription, .autoRenewableSubscription: return true
        }
    }

}

// MARK: -

extension AppleReceipt.InAppPurchase.ProductType: Codable {}
extension AppleReceipt.InAppPurchase: Codable {}

extension AppleReceipt.InAppPurchase: CustomDebugStringConvertible {

    public var debugDescription: String {
        // TODO
        return ""
//        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
