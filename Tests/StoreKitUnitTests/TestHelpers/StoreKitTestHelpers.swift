//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitTestHelpers.swift
//
//  Created by Nacho Soto on 1/24/22.

import Nimble
@testable import RevenueCat
import StoreKit
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension XCTestCase {

    private enum Error: Swift.Error {
        case invalidTransactions([StoreKit.VerificationResult<Transaction>])
    }

    func verifyNoUnfinishedTransactions(line: UInt = #line) async {
        let unfinished = await StoreKit.Transaction.unfinished.extractValues()
        expect(line: line, unfinished).to(beEmpty())
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

    func deleteAllTransactions(session: SKTestSession) async {
        let sk1Transactions = session.allTransactions()
        if !sk1Transactions.isEmpty {
            Logger.debug("Deleting \(sk1Transactions.count) transactions")

            for transaction in sk1Transactions {
                try? session.deleteTransaction(identifier: transaction.identifier)
            }
        }

        let sk2Transactions = await self.unfinishedTransactions
        if !sk2Transactions.isEmpty {
            Logger.debug("Finishing \(sk2Transactions.count) transactions")

            for transaction in sk2Transactions.map(\.underlyingTransaction) {
                await transaction.finish()
                try? session.deleteTransaction(identifier: UInt(transaction.id))
            }
        }
    }

    private var unfinishedTransactions: [StoreKit.VerificationResult<Transaction>] {
        get async { return await StoreKit.Transaction.unfinished.extractValues() }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension Product.PurchaseResult {

    var verificationResult: StoreKit.VerificationResult<Transaction>? {
        switch self {
        case let .success(verificationResult): return verificationResult
        case .userCancelled: return nil
        case .pending: return nil
        @unknown default: return nil
        }
    }

}
