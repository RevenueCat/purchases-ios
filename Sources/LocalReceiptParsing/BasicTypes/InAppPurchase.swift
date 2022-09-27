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
        let productType: ProductType?
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

    enum ProductType: Int {

        case unknown = -1,
        nonConsumable,
        consumable,
        nonRenewingSubscription,
        autoRenewableSubscription

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
