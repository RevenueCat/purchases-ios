//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

// https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
enum InAppPurchaseAttributeType: Int {
    case quantity = 1701,
         productId = 1702,
         transactionId = 1703,
         purchaseDate = 1704,
         originalTransactionId = 1705,
         originalPurchaseDate = 1706,
         productType = 1707,
         expiresDate = 1708,
         webOrderLineItemId = 1711,
         cancellationDate = 1712,
         isInTrialPeriod = 1713,
         isInIntroOfferPeriod = 1719,
         promotionalOfferIdentifier = 1721
}

enum InAppPurchaseProductType: Int {
    case unknown = -1,
         nonConsumable,
         consumable,
         nonRenewingSubscription,
         autoRenewableSubscription
}

struct InAppPurchase: Equatable {
    let quantity: Int
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let productType: InAppPurchaseProductType?
    let purchaseDate: Date
    let originalPurchaseDate: Date
    let expiresDate: Date?
    let cancellationDate: Date?
    let isInTrialPeriod: Bool?
    let isInIntroOfferPeriod: Bool
    let webOrderLineItemId: Int64
    let promotionalOfferIdentifier: String?

    var asDict: [String: Any] {
        return [
            "quantity": quantity,
            "productId": productId,
            "transactionId": transactionId,
            "originalTransactionId": originalTransactionId,
            "promotionalOfferIdentifier": promotionalOfferIdentifier ?? "",
            "purchaseDate": purchaseDate,
            "productType": productType?.rawValue ?? "",
            "originalPurchaseDate": originalPurchaseDate,
            "expiresDate": expiresDate ?? "",
            "cancellationDate": cancellationDate ?? "",
            "isInTrialPeriod": isInTrialPeriod ?? "",
            "isInIntroOfferPeriod": isInIntroOfferPeriod,
            "webOrderLineItemId": webOrderLineItemId
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }
}
