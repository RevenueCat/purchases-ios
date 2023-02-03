//
//  PurchasesReceiptParserAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 12/14/22.
//

import Foundation
import RevenueCat

func checkReceiptParserAPI() {
    let parser: PurchasesReceiptParser = .default

    do {
        let _: AppleReceipt = try parser.parse(from: Data())
        let _: AppleReceipt = try parser.parse(base64String: "")
    } catch {}
}

private func checkErrors(_ error: PurchasesReceiptParser.Error) {
    switch error {
    case .dataObjectIdentifierMissing: break
    case let .asn1ParsingError(description): print(description)
    case .receiptParsingError: break
    case .inAppPurchaseParsingError: break
    case .failedToDecodeBase64String: break
    case .receiptNotPresent: break
    case let .failedToLoadLocalReceipt(error): print(error)
    case .foundEmptyLocalReceipt: break
    @unknown default: break
    }
}

func checkAppleReceiptAPI(_ receipt: AppleReceipt! = nil) {
    let _: String = receipt.bundleId
    let _: String = receipt.applicationVersion
    let _: String? = receipt.originalApplicationVersion
    let _: Data = receipt.opaqueValue
    let _: Data = receipt.sha1Hash
    let _: Date = receipt.creationDate
    let _: Date? = receipt.expirationDate
    let _: [AppleReceipt.InAppPurchase] = receipt.inAppPurchases

    checkInAppPurchaseAPI()
    checkProductTypeEnum()
}

func checkInAppPurchaseAPI(_ purchase: AppleReceipt.InAppPurchase! = nil) {
    let _: Int = purchase.quantity
    let _: String = purchase.productId
    let _: String = purchase.transactionId
    let _: String? = purchase.originalTransactionId
    let _: AppleReceipt.InAppPurchase.ProductType = purchase.productType
    let _: Date = purchase.purchaseDate
    let _: Date? = purchase.originalPurchaseDate
    let _: Date? = purchase.expiresDate
    let _: Date? = purchase.cancellationDate
    let _: Bool? = purchase.isInTrialPeriod
    let _: Bool? = purchase.isInIntroOfferPeriod
    let _: Int64? = purchase.webOrderLineItemId
    let _: String? = purchase.promotionalOfferIdentifier
}

func checkProductTypeEnum(_ type: AppleReceipt.InAppPurchase.ProductType! = nil) {
    switch type! {
    case .unknown: break
    case .nonConsumable: break
    case .consumable: break
    case .nonRenewingSubscription: break
    case .autoRenewableSubscription: break
    @unknown default: break
    }
}
