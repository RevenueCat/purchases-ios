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

// swiftlint:disable nesting

/// The contents of a parsed IAP receipt.
struct AppleReceipt: Equatable {

    // swiftlint:disable:next line_length
    // https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
    struct Attribute {

        enum AttributeType: Int {

            case bundleId = 2,
                 applicationVersion = 3,
                 opaqueValue = 4,
                 sha1Hash = 5,
                 creationDate = 12,
                 inAppPurchase = 17,
                 originalApplicationVersion = 19,
                 expirationDate = 21

        }

        let type: AttributeType
        let version: Int
        let value: String

    }

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

}

extension AppleReceipt: Codable {}

extension AppleReceipt: CustomDebugStringConvertible {

    var debugDescription: String {
        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
