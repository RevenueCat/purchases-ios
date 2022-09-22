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

struct InAppPurchase: Equatable {

    enum ProductType: Int {

        case unknown = -1,
        nonConsumable,
        consumable,
        nonRenewingSubscription,
        autoRenewableSubscription

    }

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

    var asDict: [String: Any] {
        return [
            "quantity": quantity,
            "productId": productId,
            "transactionId": transactionId,
            "originalTransactionId": originalTransactionId ?? "<unknown>",
            "promotionalOfferIdentifier": promotionalOfferIdentifier ?? "",
            "purchaseDate": purchaseDate,
            "productType": productType?.rawValue ?? "",
            "originalPurchaseDate": originalPurchaseDate ?? "<unknown>",
            "expiresDate": expiresDate ?? "",
            "cancellationDate": cancellationDate ?? "",
            "isInTrialPeriod": isInTrialPeriod ?? "",
            "isInIntroOfferPeriod": isInIntroOfferPeriod ?? "<unknown>",
            "webOrderLineItemId": webOrderLineItemId ?? "<unknown>"
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }

}

extension InAppPurchase.ProductType: Codable {}
extension InAppPurchase: Codable {}
