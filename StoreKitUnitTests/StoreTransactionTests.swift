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

class StoreTransactionTests: StoreKitConfigTestCase {

    func testSK1DetailsWrapCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let product = MockSK1Product(mockProductIdentifier: Self.productID)
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = payment
        sk1Transaction.mockTransactionDate = Date()
        sk1Transaction.mockTransactionIdentifier = UUID().uuidString

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)

        expect(transaction.sk1Transaction) === sk1Transaction

        expect(transaction.productIdentifier) == Self.productID
        expect(transaction.purchaseDate) === sk1Transaction.mockTransactionDate
        expect(transaction.transactionIdentifier) == sk1Transaction.mockTransactionIdentifier
        expect(transaction.quantity) == payment.quantity
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2DetailsWrapCorrectly() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let sk2Transaction = try await self.simulateAnyPurchase()

        let transaction = StoreTransaction(sk2Transaction: sk2Transaction)

        // Can't use `===` because `SK2Transaction` is a `struct`
        expect(transaction.sk2Transaction) == sk2Transaction

        expect(transaction.productIdentifier) == Self.productID
        expect(transaction.purchaseDate.timeIntervalSinceNow) <= 5
        expect(transaction.transactionIdentifier) == String(sk2Transaction.id)
        expect(transaction.quantity) == sk2Transaction.purchasedQuantity
    }

    func testSk1TransactionDateBecomesAnInvalidDateIfNoDate() {
        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = SKPayment(product: MockSK1Product(mockProductIdentifier: ""))

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.purchaseDate.timeIntervalSince1970) == 0
    }

    func testSk1TransactionIdentifierBecomesARandomIDIfNoIdentifier() {
        let product = MockSK1Product(mockProductIdentifier: "")
        let payment = SKPayment(product: product)

        let sk1Transaction = MockTransaction()
        sk1Transaction.mockPayment = payment

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.transactionIdentifier).toNot(beEmpty())
    }

    func testSk1TransactionQuantityBecomes1IfNoPayment() {
        let sk1Transaction = MockTransaction()

        let transaction = StoreTransaction(sk1Transaction: sk1Transaction)
        expect(transaction.quantity) == 1
    }

}

private extension StoreTransactionTests {

    static let productID = "com.revenuecat.monthly_4.99.1_week_intro"

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func simulateAnyPurchase() async throws -> SK2Transaction {
        let product = try await fetchSk2Product()
        _ = try await product.purchase()

        let latestTransaction = await product.latestTransaction
        let transaction = try XCTUnwrap(latestTransaction)

        switch transaction {
        case let .verified(transaction):
            return transaction
        default:
            XCTFail("Invalid transaction: \(transaction)")
            fatalError("Unreachable")
        }
    }

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func fetchSk2Product() async throws -> SK2Product {
        let products: [Any] = try await StoreKit.Product.products(for: [Self.productID])
        return try XCTUnwrap(products.first as? SK2Product)
    }

}
