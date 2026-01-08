//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionMetadata.swift
//
//  Created by Antonio Pallares on 8/1/26.

import Foundation

/*
 Contains ephemeral data associated with purchases that may be lost during retry attempts.
 This data will be cached before posting receipts and cleared upon a successful post attempt.
 */
internal struct LocalTransactionMetadata: Equatable, Codable, Sendable {

    static let currentSchemaVersion: Int = 1

    /// The version of the schema used for encoding/decoding
    let schemaVersion: Int

    /// Transaction metadata keyed by a hash of transaction identifier
    var transactionMetadataByIdHash: [String: TransactionMetadata]

    init(transactionMetadataByIdHash: [String: TransactionMetadata] = [:]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.transactionMetadataByIdHash = transactionMetadataByIdHash
    }

    /// Individual transaction metadata.
    ///
    /// Contains all the information needed to retry a post receipt request for a specific transaction.
    internal struct TransactionMetadata: Equatable, Codable, Sendable {

        /// The encoded receipt data.
        let receipt: EncodedAppleReceipt

        /// Product request data (product info, pricing, discounts, etc.).
        let productData: ProductRequestData?

        /// Entity containing metadata about the purchase.
        let transactionData: PurchasedTransactionData

        /// The value of ``Purchases.purchasesAreCompletedBy`` at the time of the transaction.
        let originalPurchasesAreCompletedBy: PurchasesAreCompletedBy

        /// AppTransaction JWS string (StoreKit 2 only).
        let appTransactionJWS: String?

    }
}
