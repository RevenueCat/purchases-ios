//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreTransactionTests.swift
//
//  Created by Nacho Soto on 1/10/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class StoreTransactionTests: StoreKitConfigTestCase {

    func testSK1DetailsWrapCorrectly() async throws {
        let product = MockSK1Product(mockProductIdentifier: Self.productID)
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = payment
        sk1Transaction.mockTransactionDate = Date()
        sk1Transaction.mockTransactionIdentifier = UUID().uuidString
        sk1Transaction.mockState = .purchased

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)

        expect(transaction.sk1Transaction) === sk1Transaction

        expect(transaction.productIdentifier) == Self.productID
        expect(transaction.purchaseDate) == sk1Transaction.mockTransactionDate
        expect(transaction.transactionIdentifier) == sk1Transaction.mockTransactionIdentifier
        expect(transaction.quantity) == payment.quantity
        expect(transaction.storefront).to(beNil())
        expect(transaction.hasKnownPurchaseDate) == true
        expect(transaction.hasKnownTransactionIdentifier) == true
        expect(transaction.environment).to(beNil())
    }

    func testSK1TransactionReturnsNilRevocationFields() async throws {
        let product = MockSK1Product(mockProductIdentifier: Self.productID)
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = payment
        sk1Transaction.mockTransactionDate = Date()
        sk1Transaction.mockTransactionIdentifier = UUID().uuidString
        sk1Transaction.mockState = .purchased

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)

        expect(transaction.revocationDate).to(beNil())
        expect(transaction.revocationReason).to(beNil())
    }

    func testSK1TransactionWithMissingDate() async throws {
        let product = MockSK1Product(mockProductIdentifier: Self.productID)
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = payment
        sk1Transaction.mockTransactionDate = Date()
        sk1Transaction.mockTransactionIdentifier = UUID().uuidString
        sk1Transaction.mockState = .failed

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)

        expect(transaction.sk1Transaction) === sk1Transaction

        expect(transaction.productIdentifier) == Self.productID
        expect(transaction.purchaseDate) == Date(millisecondsSince1970: 0)
        expect(transaction.transactionIdentifier) == sk1Transaction.mockTransactionIdentifier
        expect(transaction.quantity) == payment.quantity
        expect(transaction.storefront).to(beNil())
        expect(transaction.hasKnownPurchaseDate) == false
        expect(transaction.hasKnownTransactionIdentifier) == true
        expect(transaction.jwsRepresentation).to(beNil())
        expect(transaction.environment).to(beNil())
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2DetailsWrapCorrectly() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let sk2Transaction = try await self.createTransactionWithPurchase()
        let jwsRepresentation = UUID().uuidString

        let transaction = StoreTransaction(sk2Transaction: sk2Transaction,
                                           jwsRepresentation: jwsRepresentation,
                                           environmentOverride: .sandbox)

        // Can't use `===` because `SK2Transaction` is a `struct`
        expect(transaction.sk2Transaction) == sk2Transaction

        expect(transaction.productIdentifier) == Self.productID
        expect(transaction.purchaseDate.timeIntervalSinceNow) <= 5
        expect(transaction.transactionIdentifier) == String(sk2Transaction.id)
        expect(transaction.quantity) == sk2Transaction.purchasedQuantity
        expect(transaction.hasKnownPurchaseDate) == true
        expect(transaction.hasKnownTransactionIdentifier) == true
        expect(transaction.jwsRepresentation) == jwsRepresentation
        expect(transaction.environment) == .sandbox

        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            let expected = await Storefront.currentStorefront
            expect(transaction.storefront) == expected
        } else {
            expect(transaction.storefront).to(beNil())
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testRevocationReasonMapsKnownSK2Reasons() throws {
        expect(RevocationReason(sk2RevocationReason: .developerIssue)).to(equal(.developerIssue))
        expect(RevocationReason(sk2RevocationReason: .other)).to(equal(.other))

        expect(RevocationReason.from(sk2RevocationReason: .developerIssue)) === .developerIssue
        expect(RevocationReason.from(sk2RevocationReason: .other)) === .other
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testRevocationReasonReturnsNilForUnknownSK2Reason() throws {
        expect(RevocationReason(sk2RevocationReason: .init(rawValue: 12345))).to(beNil())
        expect(RevocationReason.from(sk2RevocationReason: .init(rawValue: 12345))).to(beNil())
    }

    func testRevocationReasonValues() {
        expect(RevocationReason.developerIssue.rawValue) == "developer_issue"
        expect(RevocationReason.other.rawValue) == "other"
    }

    func testRevocationReasonRawValueInitializer() {
        expect(RevocationReason(rawValue: "developer_issue")) == .developerIssue
        expect(RevocationReason(rawValue: "other")) == .other

        let custom = RevocationReason(rawValue: "custom")

        expect(custom.rawValue) == "custom"
        expect(custom).toNot(equal(.developerIssue))
        expect(custom).toNot(equal(.other))
    }

    func testRevocationReasonHash() {
        expect(RevocationReason.developerIssue.hash) == RevocationReason.developerIssue.rawValue.hashValue
        expect(RevocationReason.other.hash) == RevocationReason.other.rawValue.hashValue
    }

    func testRevocationReasonPatternMatchingOperator() {
        expect(RevocationReason.developerIssue ~= RevocationReason(rawValue: "developer_issue")).to(beTrue())
        expect(RevocationReason.other ~= RevocationReason(rawValue: "other")).to(beTrue())

        expect(RevocationReason.developerIssue ~= RevocationReason.other).to(beFalse())
    }

    func testRevocationReasonSwitchStatementWorks() {
        let reason = RevocationReason(rawValue: "developer_issue")

        switch reason {
        case .developerIssue:
            return
        case .other:
            fail("Switch should go through developerIssue case")
        default:
            fail("Switch should go through developerIssue case")
        }

        fail("Switch should go through developerIssue case")
    }

    func testSk1TransactionDateBecomesAnInvalidDateIfNoDate() {
        let sk1Transaction = MockTransaction()
        sk1Transaction.mockTransactionDate = nil
        sk1Transaction.mockPayment = SKPayment(product: MockSK1Product(mockProductIdentifier: ""))

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.purchaseDate.timeIntervalSince1970) == 0
    }

    func testSk1TransactionIdentifierBecomesARandomIDIfNoIdentifier() {
        let product = MockSK1Product(mockProductIdentifier: "")
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockTransactionIdentifier = nil
        sk1Transaction.mockPayment = payment

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.transactionIdentifier).toNot(beEmpty())
        expect(transaction.hasKnownTransactionIdentifier) == false
    }

    func testSk1TransactionQuantityBecomes1IfNoPayment() {
        let sk1Transaction = MockTransaction()

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.quantity) == 1
    }

}
