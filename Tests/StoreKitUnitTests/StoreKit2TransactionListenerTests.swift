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
@preconcurrency import StoreKit // `PurchaseResult` is not `Sendable`
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
class StoreKit2TransactionListenerTests: StoreKitConfigTestCase {

    private var listener: StoreKit2TransactionListener! = nil
    private var delegate: MockStoreKit2TransactionListenerDelegate! = nil

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        await self.finishAllUnfinishedTransactions()

        self.delegate = .init()
        self.listener = .init(delegate: self.delegate)
    }

    func testStopsListeningToTransactions() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        expect(self.listener!.taskHandle).to(beNil())

        self.listener!.listenForTransactions(observerMode: false)
        handle = self.listener!.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    // MARK: -

    func testVerifiedTransactionReturnsOriginalTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let fakeTransaction = try await self.createTransactionWithPurchase()

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

    func testPurchasingDoesNotFinishTransactionInObserverMode() async throws {
        self.listener.listenForTransactions(observerMode: true)

        await self.verifyNoUnfinishedTransactions()

        let (_, _, purchasedTransaction) = try await self.purchase()
        expect(purchasedTransaction.ownershipType) == .purchased

        try await self.verifyUnfinishedTransaction(withId: purchasedTransaction.id)
    }

    func testPurchasingDoesNotFinishTransactionNotInObserverMode() async throws {
        self.listener.listenForTransactions(observerMode: false)

        await self.verifyNoUnfinishedTransactions()

        let (_, _, purchasedTransaction) = try await self.purchase()
        expect(purchasedTransaction.ownershipType) == .purchased

        try await self.verifyUnfinishedTransaction(withId: purchasedTransaction.id)
    }

    func testPurchasingNotifiesDelegateNotInObserverMode() throws {
        self.listener.listenForTransactions(observerMode: false)

        try self.testSession.buyProduct(productIdentifier: Self.productID)

        expect(self.delegate.invokedTransactionUpdated).toEventually(beTrue())
    }

    func testPurchasingNotifiesDelegate() throws {
        self.listener.listenForTransactions(observerMode: true)

        try self.testSession.buyProduct(productIdentifier: Self.productID)

        expect(self.delegate.invokedTransactionUpdated).toEventually(beTrue())
    }

    func testDoesNotNotifyDelegateForExistingTransactionsNotInObserverMode() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.productID)

        self.listener.listenForTransactions(observerMode: false)

        // In order for this test to not be a false positive we need to give it a chance to
        // handle the potential transaction.
        // If `observerMode` is turned on in this test, it would fail only if we wait,
        // and we can't use `toEventuallyNot(beTrue())` because that passes immediately.
        try await Task.sleep(nanoseconds: UInt64(DispatchTimeInterval.milliseconds(300).nanoseconds))

        expect(self.delegate.invokedTransactionUpdated) == false
    }

    func testNotifiesDelegateForExistingTransactionsInObserverMode() throws {
        try self.testSession.buyProduct(productIdentifier: Self.productID)

        self.listener.listenForTransactions(observerMode: true)

        expect(self.delegate.invokedTransactionUpdated).toEventually(beTrue())
    }

    func testHandlePurchaseResultDoesNotFinishTransaction() async throws {
        let (purchaseResult, _, purchasedTransaction) = try await self.purchase()

        let sk2Transaction = try await self.listener.handle(purchaseResult: purchaseResult)
        expect(sk2Transaction.transaction) == purchasedTransaction
        expect(sk2Transaction.userCancelled) == false

        try await self.verifyUnfinishedTransaction(withId: purchasedTransaction.id)
    }

    func testHandlePurchaseResultDoesNotNotifyDelegate() async throws {
        let result = try await self.purchase().result
        _ = try await self.listener.handle(purchaseResult: result)

        expect(self.delegate.invokedTransactionUpdated) == false
    }

    func testHandleUnverifiedPurchase() async throws {
        let (_, _, transaction) = try await self.purchase()

        let verificationError: VerificationResult<Transaction>.VerificationError = .invalidSignature

        do {
            _ = try await self.listener.handle(
                purchaseResult: .success(.unverified(transaction, verificationError))
            )
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))

            let underlyingError = try XCTUnwrap((error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError)
            expect(underlyingError).to(matchError(verificationError))
        }
    }

    func testHandlePurchaseResultWithCancelledPurchase() async throws {
        let result = try await self.listener.handle(purchaseResult: .userCancelled)
        expect(result.userCancelled) == true
        expect(result.transaction).to(beNil())
    }

    func testHandlePurchaseResultWithDeferredPurchase() async throws {
        do {
            _ = try await self.listener.handle(purchaseResult: .pending)
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.paymentPendingError))
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit2TransactionListenerTests {

    private enum Error: Swift.Error {
        case invalidResult(Product.PurchaseResult)
        case invalidTransactions([VerificationResult<Transaction>])
    }

    func verifyNoUnfinishedTransactions(line: UInt = #line) async {
        let unfinished = await StoreKit.Transaction.unfinished.extractValues()
        expect(line: line, unfinished).to(beEmpty())
    }

    // swiftlint:disable:next large_tuple
    func purchase() async throws -> (
        result: Product.PurchaseResult,
        verificationResult: VerificationResult<Transaction>,
        transaction: Transaction
    ) {
        let result = try await self.fetchSk2Product().purchase()

        guard case let .success(verificationResult) = result,
              case let .verified(transaction) = verificationResult
        else {
            throw Error.invalidResult(result)
        }

        return (result, verificationResult, transaction)
    }

    func verifyUnfinishedTransaction(
        withId identifier: Transaction.ID,
        line: UInt = #line
    ) async throws {
        let unfinishedTransactions = await self.unfinishedTransactions

        expect(line: line, unfinishedTransactions).to(haveCount(1))

        guard let transaction = unfinishedTransactions.onlyElement,
              case let .verified(verified) = transaction else {
            throw Error.invalidTransactions(unfinishedTransactions)
        }

        expect(line: line, verified.id) == identifier

    }

    func finishAllUnfinishedTransactions() async {
        let transactions = await self.unfinishedTransactions

        Logger.debug("Finishing \(transactions.count) transactions before running tests")

        for verificationResult in transactions {
            await verificationResult.underlyingTransaction.finish()
        }
    }

    private var unfinishedTransactions: [VerificationResult<Transaction>] {
        get async { return await StoreKit.Transaction.unfinished.extractValues() }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension VerificationResult where SignedType == Transaction {

    var underlyingTransaction: Transaction {
        switch self {
        case let .unverified(transaction, _): return transaction
        case let .verified(transaction): return transaction
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension Product.PurchaseResult {

    var verificationResult: VerificationResult<Transaction>? {
        switch self {
        case let .success(verificationResult): return verificationResult
        case .userCancelled: return nil
        case .pending: return nil
        @unknown default: return nil
        }
    }

}
