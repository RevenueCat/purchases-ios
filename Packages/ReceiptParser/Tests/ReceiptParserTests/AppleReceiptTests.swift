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

@testable import ReceiptParser

final class AppleReceiptTests: XCTestCase {

    // MARK: - containsActivePurchase

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

    func testReceiptWithExpiredPurchaseDoesNotContainActivePurchase() {
        let receipt = Self.create(with: [
            Self.productIdentifier: Date().addingTimeInterval(-1000)
        ])
        expect(receipt.containsActivePurchase(forProductIdentifier: Self.productIdentifier)) == false
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

    // MARK: - isSubscription

    func testUnknownProductTypeWithNoExpirationDateIsNotSubscription() {
        let purchase = Self.create(with: .unknown, expiration: nil)
        expect(purchase.isSubscription) == false
    }

    func testUnknownProductTypeWithExpirationDateIsSubscription() {
        let purchase = Self.create(with: .unknown, expiration: Date().addingTimeInterval(10))
        expect(purchase.isSubscription) == true
    }

    func testNonConsumablePurchaseIsNotSubscription() {
        let purchase = Self.create(with: .nonConsumable, expiration: nil)
        expect(purchase.isSubscription) == false
    }

    func testConsumablePurchaseIsNotSubscription() {
        let purchase = Self.create(with: .consumable, expiration: nil)
        expect(purchase.isSubscription) == false
    }

    func testNonRenewingSubscriptionIsSubscription() {
        let purchase = Self.create(with: .nonRenewingSubscription, expiration: Date())
        expect(purchase.isSubscription) == true
    }

    func testAutoRenewingSubscriptionIsSubscription() {
        let purchase = Self.create(with: .autoRenewableSubscription, expiration: Date())
        expect(purchase.isSubscription) == true
    }

    // MARK: - purchaseDateEqualsExpiration

    func testPurchaseDateEqualsExpirationWithNoSubscription() {
        expect(
            Self.create(with: [ Self.productIdentifier: nil ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == false
    }

    func testExpirationDate10SecondsAfterPurchase() {
        expect(
            Self.create(with: [ Self.productIdentifier: Date().addingTimeInterval(10) ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == false
    }

    func testExpirationDate5SecondsAfterPurchase() {
        expect(
            Self.create(with: [ Self.productIdentifier: Date().addingTimeInterval(5) ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == true
    }

    func testExpirationDateSameAsPurchase() {
        expect(
            Self.create(with: [ Self.productIdentifier: Date() ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == true
    }

    func testExpirationDate4SecondsBeforePurchase() {
        expect(
            Self.create(with: [ Self.productIdentifier: Date().addingTimeInterval(-4) ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == true
    }

    func testExpirationDate10SecondsBeforePurchaseIsNotTheSame() {
        expect(
            Self.create(with: [ Self.productIdentifier: Date().addingTimeInterval(-10) ])
                .inAppPurchases
                .first!
                .purchaseDateEqualsExpiration
        ) == false
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
                Self.create(with: expiration == nil
                            ? .nonConsumable
                            : .autoRenewableSubscription,
                            identifier: identifier,
                            expiration: expiration)
            }
        )
    }

    static func create(
        with productType: AppleReceipt.InAppPurchase.ProductType,
        identifier: String = UUID().uuidString,
        expiration: Date?
    ) -> AppleReceipt.InAppPurchase {
        return .init(
            quantity: 1,
            productId: identifier,
            transactionId: "transaction-\(identifier)",
            originalTransactionId: nil,
            productType: productType,
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

}
