//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppleReceiptTests.swift
//
//  Created by Nacho Soto on 9/27/22.

import Nimble
import XCTest

@testable import RevenueCat

final class AppleReceiptTests: TestCase {

    func testReceiptWithNoPurchasesDoesNotContainActivePurchase() {
        let receipt = Self.create(with: [:])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == false
    }

    func testReceiptWithPurchaseContainsActivePurchaseWithDifferentProductIdentifier() {
        let receipt = Self.create(with: [
            "different_product": Date().addingTimeInterval(1000)
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == true
    }

    func testReceiptWithExpiredPurchaseContainsActivePurchase() {
        let receipt = Self.create(with: [
            Self.productIdentifier: Date().addingTimeInterval(-1000)
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == true
    }

    func testReceiptWithNonExpiringPurchaseContainsActivePurchase() {
        let receipt = Self.create(with: [
            Self.productIdentifier: nil
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == true
    }

    func testReceiptWithNotExpiredPurchaseContainsActivePurchase() {
        let receipt = Self.create(with: [
            Self.productIdentifier: Date().addingTimeInterval(1000)
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == true
    }

    func testReceiptWithSubscriptionActiveForDifferentProductContainsActivePurchase() {
        let receipt = Self.create(with: [
            "different_product": Date().addingTimeInterval(1000)
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == true
    }

    func testReceiptWithNonConsumablePurchaseForDifferentProductDoesNotContainActivePurchase() {
        let receipt = Self.create(with: [
            "different_product": nil
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == false
    }

    // MARK: -

    private static let productIdentifier = "com.revenuecat.product_a"
}

// MARK: -

private extension AppleReceiptTests {

    static func create(with expirationDatesByProductIdentifier: [String: Date?]) -> AppleReceipt {
        return .init(
            bundleId: "com.revenuecat.test_app",
            applicationVersion: "1.0",
            originalApplicationVersion: nil,
            opaqueValue: Data(),
            sha1Hash: Data(),
            creationDate: Date(),
            expirationDate: nil,
            inAppPurchases: expirationDatesByProductIdentifier.map { identifier, expiration in
                .init(
                    quantity: 1,
                    productId: identifier,
                    transactionId: "transaction-\(identifier)",
                    originalTransactionId: nil,
                    productType: expiration == nil
                        ? .nonConsumable
                        : .autoRenewableSubscription,
                    purchaseDate: Date(),
                    originalPurchaseDate: nil,
                    expiresDate: expiration,
                    cancellationDate: nil,
                    isInTrialPeriod: nil,
                    isInIntroOfferPeriod: nil,
                    webOrderLineItemId: nil,
                    promotionalOfferIdentifier: nil
                )
            }
        )
    }

}
