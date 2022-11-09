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

    struct InAppPurchase: Equatable {

        let quantity: Int
        let productId: String
        let transactionId: String
        let originalTransactionId: String?
        let productType: ProductType
        let purchaseDate: Date
        let originalPurchaseDate: Date?
        let expiresDate: Date?
        let cancellationDate: Date?
        let isInTrialPeriod: Bool?
        let isInIntroOfferPeriod: Bool?
        let webOrderLineItemId: Int64?
        let promotionalOfferIdentifier: String?

    }

}

extension AppleReceipt.InAppPurchase {

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

    enum ProductType: Int {

        case unknown = -1,
        nonConsumable,
        consumable,
        nonRenewingSubscription,
        autoRenewableSubscription

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

extension AppleReceipt.InAppPurchase.ProductType: Codable {}
extension AppleReceipt.InAppPurchase: Codable {}

extension AppleReceipt.InAppPurchase: CustomDebugStringConvertible {

    var debugDescription: String {
        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
