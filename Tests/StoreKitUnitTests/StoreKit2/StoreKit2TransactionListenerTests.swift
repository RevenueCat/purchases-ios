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
import StoreKit
import StoreKitTest
import XCTest

// swiftlint:disable type_name

@MainActor
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListenerBaseTests: StoreKitConfigTestCase {

    typealias TransactionResult = StoreKit2TransactionListener.TransactionResult

    fileprivate var listener: StoreKit2TransactionListener! = nil
    fileprivate var delegate: MockStoreKit2TransactionListenerDelegate! = nil

    var updates: AsyncStream<TransactionResult> {
        get async throws {
            return Transaction.updates.toAsyncStream()
        }
    }

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        // Unfinished transactions before beginning the test might lead to false positives / negatives
        await self.verifyNoUnfinishedTransactions()

        self.delegate = .init()
        self.listener = .init(delegate: self.delegate, updates: try await self.updates)
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListenerTests: StoreKit2TransactionListenerBaseTests {

    func testStopsListeningToTransactions() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        handle = await self.listener.taskHandle
        expect(handle).to(beNil())

        await self.listener.listenForTransactions()
        handle = await self.listener.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    // MARK: -

    func testVerifiedTransactionReturnsOriginalTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let fakeTransaction = try await self.simulateAnyPurchase()

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

        let transaction = try await self.simulateAnyPurchase()
        let error: StoreKit.VerificationResult<Transaction>.VerificationError = .invalidSignature
        let result: StoreKit.VerificationResult<Transaction> = .unverified(transaction, error)

        // Note: can't use `expect().to(throwError)` or `XCTAssertThrowsError`
        // because neither of them accept `async`
        do {
            _ = try await self.listener.handle(purchaseResult: .success(result))
            XCTFail("Error expected")
        } catch {
            expect(error).to(matchError(ErrorCode.storeProblemError))
        }
    }

    func testPurchasingDoesNotFinishTransaction() async throws {
        await self.listener.listenForTransactions()

        await self.verifyNoUnfinishedTransactions()

        let (_, _, purchasedTransaction) = try await self.purchase()
        expect(purchasedTransaction.ownershipType) == .purchased

        try await self.verifyUnfinishedTransaction(withId: purchasedTransaction.id)
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

        let verificationError: StoreKit.VerificationResult<Transaction>.VerificationError = .invalidSignature

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

// MARK: - Transaction.updates tests

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListenerTransactionUpdatesTests: StoreKit2TransactionListenerBaseTests {

    func testPurchasingInTheAppDoesNotNotifyDelegate() async throws {
        await self.listener.listenForTransactions()

        try await self.simulateAnyPurchase(finishTransaction: true)
        try await self.verifyTransactionsWereNotUpdated()
    }

    func testPurchasingOutsideTheAppNotifiesDelegate() async throws {
        await self.listener.listenForTransactions()

        try self.testSession.buyProduct(productIdentifier: Self.productID)

        try await asyncWait {
            await self.delegate.invokedTransactionUpdated == true
        }
    }

    func testNotifiesDelegateForExistingTransactions() async throws {
        try self.testSession.buyProduct(productIdentifier: Self.productID)

        await self.listener.listenForTransactions()

        try await asyncWait {
            await self.delegate.invokedTransactionUpdated == true
        }
    }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    func testNotifiesDelegateForRenewals() async throws {
        try await self.simulateAnyPurchase(finishTransaction: true)

        await self.listener.listenForTransactions()

        try? self.testSession.forceRenewalOfSubscription(productIdentifier: Self.productID)

        try await self.waitForTransactionUpdated()

        expect(self.delegate.updatedTransactions)
            .to(containElementSatisfying { transaction in
                transaction.productIdentifier == Self.productID
            })

        self.logger.verifyMessageWasLogged(Strings.purchase.sk2_transactions_update_received_transaction(
            productID: Self.productID
        ))
    }

}

// MARK: - Tests with custom stream

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListenerCustomStreamTests: StoreKit2TransactionListenerBaseTests {

    override var updates: AsyncStream<TransactionResult> {
        get async throws {
            return MockAsyncSequence<TransactionResult>(with: [
                .verified(try await self.createTransactionWithPurchase()),
                .verified(try await self.createTransactionWithPurchase()),
                .unverified(
                    try await self.createTransactionWithPurchase(),
                    .revokedCertificate
                )
            ])
            .toAsyncStream()
        }
    }

    func testHandlesAllVerifiedTransactions() async throws {
        await self.listener.listenForTransactions()

        try await asyncWait {
            return await self.delegate.updatedTransactions.count == 2
        }
    }

    func testHandlesTransactionsAsynchronously() async throws {
        self.delegate.fakeHandlingDelay = .milliseconds(50)

        await self.listener.listenForTransactions()

        try await asyncWait {
            return await self.delegate.updatedTransactions.count == 2
        }

        expect(self.delegate.receivedConcurrentRequest) == true
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit2TransactionListenerBaseTests {

    private enum Error: Swift.Error {
        case invalidResult(Product.PurchaseResult)
    }

    func purchase() async throws -> (
        result: Product.PurchaseResult,
        verificationResult: StoreKit.VerificationResult<Transaction>,
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

    func verifyTransactionsWereNotUpdated() async throws {
        // In order for this test to not be a false positive we need to
        // give it a chance to handle the potential transaction.
        try await Task.sleep(nanoseconds: UInt64(DispatchTimeInterval.milliseconds(300).nanoseconds))

        expect(self.delegate.invokedTransactionUpdated) == false
    }

    func waitForTransactionUpdated(
        file: FileString = #fileID,
        line: UInt = #line
    ) async throws {
        try await asyncWait(
            description: "Transaction update",
            timeout: .seconds(4),
            pollInterval: .milliseconds(100),
            file: file,
            line: line
        ) {
            await self.delegate.invokedTransactionUpdated == true
        }
    }

}
