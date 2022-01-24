//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionListenerTests.swift
//
//  Created by Nacho Soto on 1/14/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListenerTests: StoreKitConfigTestCase {

    private var listener: StoreKit2TransactionListener! = nil

    override func setUp() {
        super.setUp()

        self.listener = .init(delegate: nil)
    }

    func testStopsListeningToTransactions() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        expect(self.listener!.taskHandle).to(beNil())

        self.listener!.listenForTransactions()
        handle = self.listener!.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    // MARK: -

    func testCancelled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let isCancelled = try await self.listener.handle(purchaseResult: .userCancelled)
        expect(isCancelled) == true
    }

    func testTransactionIsPending() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // Note: can't use `expect().to(throwError)` or `XCTAssertThrowsError`
        // because neither of them accept `async`
        do {
            _ = try await self.listener.handle(purchaseResult: .pending)
            XCTFail("Error expected")
        } catch {
            expect(error).to(matchError(ErrorCode.paymentPendingError))
        }
    }

    func testUnverifiedTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let transaction = try await self.createTransactionWithPurchase()
        let error: VerificationResult<Transaction>.VerificationError = .invalidSignature
        let result: VerificationResult<Transaction> = .unverified(transaction, error)

        // Note: can't use `expect().to(throwError)` or `XCTAssertThrowsError`
        // because neither of them accept `async`
        do {
            _ = try await self.listener.handle(purchaseResult: .success(result))
            XCTFail("Error expected")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit2TransactionListenerTests {

    @MainActor
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func createTransactionWithPurchase() async throws -> Transaction {
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
        let products: [Any] = try await StoreKit.Product.products(for: ["com.revenuecat.monthly_4.99.1_week_intro"])
        return try XCTUnwrap(products.first as? SK2Product)
    }

}
