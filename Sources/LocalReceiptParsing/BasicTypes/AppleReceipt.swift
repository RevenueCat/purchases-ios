//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppleReceipt.swift
//
//  Created by Andrés Boedo on 7/22/20.
//

import Foundation

// https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
struct ReceiptAttribute {

    let type: ReceiptAttributeType
    let version: Int
    let value: String

}

enum ReceiptAttributeType: Int {

    case bundleId = 2,
         applicationVersion = 3,
         opaqueValue = 4,
         sha1Hash = 5,
         creationDate = 12,
         inAppPurchase = 17,
         originalApplicationVersion = 19,
         expirationDate = 21

}

struct AppleReceipt: Equatable {

    let bundleId: String
    let applicationVersion: String
    let originalApplicationVersion: String?
    let opaqueValue: Data
    let sha1Hash: Data
    let creationDate: Date
    let expirationDate: Date?
    let inAppPurchases: [InAppPurchase]

    func purchasedIntroOfferOrFreeTrialProductIdentifiers() -> Set<String> {
        let productIdentifiers = inAppPurchases
            .filter { $0.isInIntroOfferPeriod == true || $0.isInTrialPeriod == true }
            .map { $0.productId }
        return Set(productIdentifiers)
    }

    var asDict: [String: Any] {
        return [
            "bundleId": bundleId,
            "applicationVersion": applicationVersion,
            "originalApplicationVersion": originalApplicationVersion ?? "<unknown>",
            "opaqueValue": opaqueValue,
            "sha1Hash": sha1Hash,
            "creationDate": creationDate,
            "expirationDate": expirationDate ?? "",
            "inAppPurchases": inAppPurchases.map { $0.asDict }
        ]
    }

    var description: String {
        return String(describing: self.asDict)
    }

}
