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
internal struct LocalTransactionMetadata: Codable, Sendable {

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
    internal struct TransactionMetadata: Codable, Sendable {

        /// The encoded receipt data.
        let receipt: EncodedAppleReceipt

        private let productDataWrapper: ProductRequestDataEncodedWrapper?

        /// Product request data (product info, pricing, discounts, etc.).
        var productData: ProductRequestData? {
            return productDataWrapper?.productRequestData
        }

        private let purchasedTransactionDataWrapper: PurchasedTransactionDataEncodedWrapper

        /// Entity containing metadata about the purchase.
        var transactionData: PurchasedTransactionData {
            return self.purchasedTransactionDataWrapper.purchasedTransactionData
        }

        /// The value of ``Purchases.purchasesAreCompletedBy`` at the time of the transaction.
        let originalPurchasesAreCompletedBy: PurchasesAreCompletedBy

        /// AppTransaction JWS string (StoreKit 2 only).
        let appTransactionJWS: String?

        init(
            receipt: EncodedAppleReceipt,
            productData: ProductRequestData?,
            transactionData: PurchasedTransactionData,
            originalPurchasesAreCompletedBy: PurchasesAreCompletedBy,
            appTransactionJWS: String?
        ) {
            self.receipt = receipt
            self.productDataWrapper = productData.map(ProductRequestDataEncodedWrapper.init)
            self.purchasedTransactionDataWrapper = PurchasedTransactionDataEncodedWrapper(
                purchasedTransactionData: transactionData
            )
            self.originalPurchasesAreCompletedBy = originalPurchasesAreCompletedBy
            self.appTransactionJWS = appTransactionJWS
        }

    }
}

// MARK: - Codable wrappers

// Some existing types are not trivial to make `Codable`, or they are public and/or their existing `Encodable`
// implementation is not suitable for a lossless decoding/encoding.
// These wrappers allow us to encode/decode them without modifying their existing implementations.

private struct ProductRequestDataEncodedWrapper: Sendable, Codable {

    // We persist every `ProductRequestData` stored property, so encoding/decoding is lossless.
    // Note: we intentionally do not rely on `ProductRequestData: Encodable` because that `Encodable` implementation
    // is destined for sending data to the backend, and not all information is encoded. Decoding it would result in a
    // `ProductRequestData` missing some information from the original one.

    private let productIdentifier: String
    private let paymentModeRawValue: Int?
    private let currencyCode: String?
    private let storefrontWrapper: StorefrontEncodedWrapper?
    private let priceString: String
    private let normalDuration: String?
    private let introDuration: String?
    private let introDurationTypeRawValue: Int?
    private let introPriceString: String?
    private let subscriptionGroup: String?
    private let discounts: [StoreProductDiscountEncodedWrapper]?

    init(productRequestData: ProductRequestData) {
        self.productIdentifier = productRequestData.productIdentifier
        self.paymentModeRawValue = productRequestData.paymentMode?.rawValue
        self.currencyCode = productRequestData.currencyCode
        self.storefrontWrapper = productRequestData.storefront.map(StorefrontEncodedWrapper.init(storefront:))
        self.priceString = Self.encodeDecimal(productRequestData.price)
        self.normalDuration = productRequestData.normalDuration
        self.introDuration = productRequestData.introDuration
        self.introDurationTypeRawValue = productRequestData.introDurationType?.rawValue
        self.introPriceString = productRequestData.introPrice.map(Self.encodeDecimal(_:))
        self.subscriptionGroup = productRequestData.subscriptionGroup
        self.discounts = productRequestData.discounts?.map(StoreProductDiscountEncodedWrapper.init(discount:))
    }

    var productRequestData: ProductRequestData {
        return .init(
            productIdentifier: self.productIdentifier,
            paymentMode: self.paymentModeRawValue.flatMap(StoreProductDiscount.PaymentMode.init(rawValue:)),
            currencyCode: self.currencyCode,
            storefront: self.storefrontWrapper,
            price: Self.decodeDecimal(from: self.priceString) ?? 0,
            normalDuration: self.normalDuration,
            introDuration: self.introDuration,
            introDurationType: self.introDurationTypeRawValue.flatMap(StoreProductDiscount.PaymentMode.init(rawValue:)),
            introPrice: self.introPriceString.flatMap(Self.decodeDecimal(from:)),
            subscriptionGroup: self.subscriptionGroup,
            discounts: self.discounts?.map({ $0.discount })
        )
    }

    // Encode decimals as strings to preserve exact precision.
    private static func encodeDecimal(_ decimal: Decimal) -> String {
        return (decimal as NSDecimalNumber).description
    }

    private static func decodeDecimal(from string: String) -> Decimal? {
        return Decimal(string: string)
    }
}

private struct PurchasedTransactionDataEncodedWrapper: Codable {
    private let appUserId: String
    private let presentedOfferingContext: PresentedOfferingContext?
    private let presentedPaywall: PaywallEvent?
    private let unsyncedAttributes: SubscriberAttribute.Dictionary?
    private let metadata: [String: String]?
    private let aadAttributionToken: String?
    private let storefrontWrapper: StorefrontEncodedWrapper?
    private let source: PurchaseSource

    init(purchasedTransactionData: PurchasedTransactionData) {
        self.appUserId = purchasedTransactionData.appUserID
        self.presentedOfferingContext = purchasedTransactionData.presentedOfferingContext
        self.presentedPaywall = purchasedTransactionData.presentedPaywall
        self.unsyncedAttributes = purchasedTransactionData.unsyncedAttributes
        self.metadata = purchasedTransactionData.metadata
        self.aadAttributionToken = purchasedTransactionData.aadAttributionToken
        self.storefrontWrapper = purchasedTransactionData.storefront.map(StorefrontEncodedWrapper.init(storefront:))
        self.source = purchasedTransactionData.source
    }

    var purchasedTransactionData: PurchasedTransactionData {
        return PurchasedTransactionData(
            appUserID: self.appUserId,
            presentedOfferingContext: self.presentedOfferingContext,
            presentedPaywall: self.presentedPaywall,
            unsyncedAttributes: self.unsyncedAttributes,
            metadata: self.metadata,
            aadAttributionToken: self.aadAttributionToken,
            storefront: self.storefrontWrapper,
            source: self.source
        )
    }
}

/// Wrapper around `StoreProductDiscountType` to make it `Codable`.
private struct StoreProductDiscountEncodedWrapper: StoreProductDiscountType, Codable {
    let offerIdentifier: String?
    let currencyCode: String?
    let price: Decimal
    let localizedPriceString: String
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod
    let numberOfPeriods: Int
    let type: StoreProductDiscount.DiscountType

    init(discount: StoreProductDiscount) {
        self.offerIdentifier = discount.offerIdentifier
        self.currencyCode = discount.currencyCode
        self.price = discount.price
        self.localizedPriceString = discount.localizedPriceString
        self.paymentMode = discount.paymentMode
        self.subscriptionPeriod = discount.subscriptionPeriod
        self.numberOfPeriods = discount.numberOfPeriods
        self.type = discount.type
    }

    var discount: StoreProductDiscount {
        return StoreProductDiscount(self)
    }
}

/// Wrapper around `StorefrontType` to make it `Codable`.
private struct StorefrontEncodedWrapper: StorefrontType, Codable {
    let countryCode: String
    let identifier: String

    init(storefront: StorefrontType) {
        self.countryCode = storefront.countryCode
        self.identifier = storefront.identifier
    }
}
