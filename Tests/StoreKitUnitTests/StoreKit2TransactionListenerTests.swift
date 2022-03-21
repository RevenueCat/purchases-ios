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

    func testVerifiedTransactionReturnsOriginalTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let fakeTransaction = try await createTransactionWithPurchase()

        let (isCancelled, transaction) = try await self.listener.handle(
            purchaseResult: .success(.verified(fakeTransaction))
        )
        expect(isCancelled) == false
        expect(transaction) == fakeTransaction
    }

    func testIsCancelledIsTrueWhenPurchaseIsCancelled() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let (isCancelled, transaction) = try await self.listener.handle(purchaseResult: .userCancelled)
        expect(isCancelled) == true
        expect(transaction).to(beNil())
    }

    func testPendingTransactionsReturnPaymentPendingError() async throws {
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

    func testUnverifiedTransactionsReturnStoreProblemError() async throws {
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
