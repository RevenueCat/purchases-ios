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
public struct AppleReceipt: Equatable {

    // swiftlint:disable:next line_length
    // https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
    public struct Attribute {

        public enum AttributeType: Int {

            case bundleId = 2,
                 applicationVersion = 3,
                 opaqueValue = 4,
                 sha1Hash = 5,
                 creationDate = 12,
                 inAppPurchase = 17,
                 originalApplicationVersion = 19,
                 expirationDate = 21

        }

        public let type: AttributeType
        public let version: Int
        public let value: String

    }

    public let bundleId: String
    public let applicationVersion: String
    public let originalApplicationVersion: String?
    public let opaqueValue: Data
    public let sha1Hash: Data
    public let creationDate: Date
    public let expirationDate: Date?
    public let inAppPurchases: [InAppPurchase]

    public func purchasedIntroOfferOrFreeTrialProductIdentifiers() -> Set<String> {
        let productIdentifiers = self.inAppPurchases
            .filter { $0.isInIntroOfferPeriod == true || $0.isInTrialPeriod == true }
            .map { $0.productId }
        return Set(productIdentifiers)
    }

}

// MARK: - Extensions

public extension AppleReceipt {

    func containsActivePurchase(forProductIdentifier identifier: String) -> Bool {
        return (
            self.inAppPurchases.contains { $0.isActiveSubscription } ||
            self.inAppPurchases.contains { !$0.isSubscription && $0.productId == identifier }
        )
    }

}

// MARK: - Conformances

extension AppleReceipt: Codable {}

extension AppleReceipt: CustomDebugStringConvertible {

    public var debugDescription: String {
        // TODO
        return "TODO"
//        return (try? self.prettyPrintedJSON) ?? "<null>"
    }

}
